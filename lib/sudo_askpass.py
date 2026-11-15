#!/usr/bin/python3
"""Return a password only to sudo's private pipe, never to installer logs."""
import sys
import tkinter as tk
from tkinter import simpledialog

root = tk.Tk()
root.withdraw()
password = simpledialog.askstring('Linux To Go · 系统授权',
                                 '安装系统软件需要管理员权限，请输入当前用户的 sudo 密码：',
                                 show='*', parent=root)
root.destroy()
if password is None:
    sys.exit(1)
sys.stdout.write(password + '\n')
