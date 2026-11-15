#!/usr/bin/env python3
"""Dependency-free Tk deployment UI; Bash remains the installation backend."""
import argparse
import datetime
import os
from pathlib import Path
import queue
import subprocess
import sys
import threading
import tkinter as tk
from tkinter import messagebox, ttk
from tkinter.scrolledtext import ScrolledText


def read_status(backend):
    result = subprocess.run([str(backend), '--status'], capture_output=True,
                            text=True, timeout=30)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip())
    return dict(line.split('\t', 1) for line in result.stdout.splitlines() if '\t' in line)


def ros_choices(status):
    version = status.get('version')
    return [('ros1', 'ROS 1 Noetic（Ubuntu 20.04，已结束维护）', version == '20.04'),
            ('ros2', 'ROS 2 Humble（22.04）/ Jazzy（24.04）', version in ('22.04', '24.04')),
            ('--apps-only', '保留当前 ROS / 仅安装应用', True)]


def initial_mode(status):
    if status.get('ros1') or status.get('ros2'):
        return '--apps-only'
    return 'ros1' if status.get('version') == '20.04' else 'ros2'


def install_args(backend, mode, clash, nomachine, dry_run=False):
    args = [str(backend), '--' + mode if mode in ('ros1', 'ros2') else mode]
    if not clash:
        args.append('--skip-clash')
    if not nomachine:
        args.append('--skip-nomachine')
    if dry_run:
        args.append('--dry-run')
    return args


class Installer:
    def __init__(self, root, backend, preview=False):
        self.root, self.backend, self.preview = root, Path(backend).resolve(), preview
        self.events, self.busy, self.process = queue.Queue(), False, None
        self.status = {}
        root.title('Linux To Go · 一键部署环境')
        root.geometry('960x760')
        root.minsize(820, 680)
        root.configure(bg='#f2f5fa')
        style = ttk.Style(root)
        style.theme_use('clam')
        style.configure('TFrame', background='#f2f5fa')
        style.configure('TLabel', background='#f2f5fa', foreground='#17243b', font=('Sans', 11))
        style.configure('Title.TLabel', font=('Sans', 23, 'bold'))
        style.configure('TButton', padding=9)
        outer = ttk.Frame(root, padding=24)
        outer.pack(fill='both', expand=True)
        ttk.Label(outer, text='Linux To Go', style='Title.TLabel').pack(anchor='w')
        ttk.Label(outer, text='检测电脑 → 选择 ROS → 自动匹配架构并安装', padding=(0, 8)).pack(anchor='w')
        self.system_text = tk.StringVar(value='正在检测系统和现有环境…')
        ttk.Label(outer, textvariable=self.system_text, wraplength=880).pack(anchor='w', pady=(8, 12))
        self.ros_box = ttk.LabelFrame(outer, text='ROS 环境', padding=12)
        self.ros_box.pack(fill='x')
        self.mode = tk.StringVar(value='--apps-only')
        self.mode_buttons = []
        self.ros_status = tk.StringVar()
        ttk.Label(self.ros_box, textvariable=self.ros_status).pack(anchor='w', pady=(0, 6))
        self.apps_box = ttk.LabelFrame(outer, text='应用 · 使用本仓库 Releases', padding=12)
        self.apps_box.pack(fill='x', pady=12)
        self.clash, self.nomachine = tk.BooleanVar(value=True), tk.BooleanVar(value=True)
        self.clash_check = ttk.Checkbutton(self.apps_box, text='Clash Verge 2.5.10', variable=self.clash)
        self.clash_check.pack(anchor='w')
        self.nm_check = ttk.Checkbutton(self.apps_box, text='NoMachine（按 amd64 / arm64 自动选择）', variable=self.nomachine)
        self.nm_check.pack(anchor='w', pady=4)
        self.note = tk.StringVar(value='已安装组件将跳过。安装时系统会弹窗请求管理员密码。')
        ttk.Label(outer, textvariable=self.note, wraplength=880).pack(anchor='w')
        bar = ttk.Frame(outer)
        bar.pack(fill='x', pady=12)
        self.refresh_btn = ttk.Button(bar, text='重新检测', command=self.refresh)
        self.refresh_btn.pack(side='left')
        self.plan_btn = ttk.Button(bar, text='预览安装计划', command=lambda: self.start(True))
        self.plan_btn.pack(side='left', padx=8)
        self.install_btn = ttk.Button(bar, text='开始部署', command=lambda: self.start(False))
        self.install_btn.pack(side='right')
        self.progress = ttk.Progressbar(outer, mode='indeterminate')
        self.progress.pack(fill='x')
        self.output = ScrolledText(outer, height=12, font=('Monospace', 10), bg='#142035', fg='#e3ebf7')
        self.output.pack(fill='both', expand=True, pady=(12, 0))
        self.output.configure(state='disabled')
        self.log_path = None
        root.protocol('WM_DELETE_WINDOW', self.close)
        root.after(80, self.drain)
        self.refresh()

    def set_busy(self, busy):
        self.busy = busy
        for widget in [self.refresh_btn, self.plan_btn, self.install_btn,
                       self.clash_check, self.nm_check, *self.mode_buttons]:
            widget.configure(state='disabled' if busy else 'normal')
        if not busy:
            for button, choice in zip(self.mode_buttons, ros_choices(self.status)):
                if not choice[2]:
                    button.configure(state='disabled')
            if self.status.get('version') == '20.04' and self.status.get('clash') != 'installed':
                self.clash_check.configure(state='disabled')
        if busy:
            self.progress.start(12)
        else:
            self.progress.stop()

    def refresh(self):
        if self.busy:
            return
        self.set_busy(True)
        def work():
            try:
                self.events.put(('status', read_status(self.backend)))
            except Exception as exc:
                self.events.put(('error', str(exc)))
        threading.Thread(target=work, daemon=True).start()

    def apply_status(self, status):
        self.status = status
        self.system_text.set(f"系统：{status.get('os')} {status.get('version')}    CPU/软件包架构：{status.get('arch')}")
        self.ros_status.set(f"ROS 1：{status.get('ros1') or '未检测到'}    ROS 2：{status.get('ros2') or '未检测到'}")
        for button in self.mode_buttons:
            button.destroy()
        self.mode_buttons = []
        self.mode.set(initial_mode(status))
        for value, label, allowed in ros_choices(status):
            button = ttk.Radiobutton(self.ros_box, text=label, variable=self.mode, value=value)
            button.pack(anchor='w', pady=3)
            self.mode_buttons.append(button)
        self.clash_check.configure(text=f"Clash Verge 2.5.10 · {'已安装，将跳过' if status.get('clash') == 'installed' else '待安装'}")
        self.nm_check.configure(text=f"NoMachine · {'已安装，将跳过' if status.get('nomachine') == 'installed' else '待安装'} · {status.get('arch')}")
        if status.get('version') == '20.04' and status.get('clash') != 'installed':
            self.clash.set(False)
            self.note.set('Ubuntu 20.04 缺少此版 Clash 所需 WebKit 4.1；已禁用该项。Noetic 已结束维护。')
        else:
            self.note.set('已有 ROS 默认保留；不兼容的版本不可选。Clash 订阅需安装后自行导入。')
        self.set_busy(False)
        if status.get('os') != 'ubuntu' or status.get('version') not in ('20.04', '22.04', '24.04') or status.get('arch') not in ('amd64', 'arm64'):
            self.install_btn.configure(state='disabled')
            self.note.set('当前仅支持 Ubuntu 20.04 / 22.04 / 24.04 的 amd64、arm64；未修改系统。')

    def start(self, dry_run):
        if self.busy:
            return
        dry_run = dry_run or self.preview
        args = install_args(self.backend, self.mode.get(), self.clash.get(), self.nomachine.get(), dry_run)
        self.set_busy(True)
        stamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f')
        directory = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'linux-to-go'
        try:
            directory.mkdir(parents=True, exist_ok=True)
            self.log_path = directory / (stamp + '.log')
        except OSError as exc:
            self.set_busy(False)
            messagebox.showerror('无法创建日志', str(exc))
            return
        self.append(f"\n{'预览' if dry_run else '开始部署'} · 日志：{self.log_path}\n")
        env = os.environ.copy()
        # Backend installation runs in one privileged process; the password
        # goes straight from the isolated askpass dialog to sudo, never logs.
        if not dry_run and os.geteuid() != 0:
            env['SUDO_ASKPASS'] = str(Path(__file__).with_name('sudo_askpass.py').resolve())
            args = ['sudo', '-A', '--', *args]
        def work():
            try:
                with self.log_path.open('w', encoding='utf-8') as logfile:
                    self.process = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                                    text=True, errors='replace', env=env)
                    for line in self.process.stdout:
                        logfile.write(line)
                        logfile.flush()
                        self.events.put(('line', line))
                    code = self.process.wait()
                self.events.put(('done', (code, dry_run)))
            except Exception as exc:
                self.events.put(('error', str(exc)))
            finally:
                self.process = None
        threading.Thread(target=work, daemon=True).start()

    def append(self, text):
        self.output.configure(state='normal')
        self.output.insert('end', text)
        self.output.see('end')
        self.output.configure(state='disabled')

    def drain(self):
        try:
            while True:
                kind, value = self.events.get_nowait()
                if kind == 'line':
                    self.append(value)
                elif kind == 'status':
                    self.apply_status(value)
                elif kind == 'error':
                    self.set_busy(False)
                    self.append(value + '\n')
                    messagebox.showerror('部署未完成', value)
                elif kind == 'done':
                    self.set_busy(False)
                    code, preview = value
                    if code == 0:
                        messagebox.showinfo('完成', '安装计划预览完成，未修改系统。' if preview else '部署完成。Clash 请导入订阅；ROS 请在新终端中使用。')
                        if not preview:
                            self.refresh()
                    else:
                        messagebox.showerror('部署未完成', f'退出码 {code}。请查看窗口输出及日志：\n{self.log_path}\n已完成的安装会保留，可修复后重新运行。')
        except queue.Empty:
            pass
        self.root.after(80, self.drain)

    def close(self):
        if self.busy:
            messagebox.showinfo('正在执行', '请等待当前任务完成，避免中断系统软件包配置。')
            return
        self.root.destroy()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('backend')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--live', action='store_true')
    args = parser.parse_args()
    try:
        root = tk.Tk()
    except tk.TclError as exc:
        print(f'[ERROR] 无法打开图形界面：{exc}。可在终端运行 --auto 或 --ros2。', file=sys.stderr)
        return 2
    Installer(root, args.backend, preview=args.dry_run)
    root.mainloop()
    return 0


if __name__ == '__main__':
    sys.exit(main())
