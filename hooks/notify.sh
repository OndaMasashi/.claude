#!/bin/bash
# カスタム通知 (Notification)
# Claude Code が入力を待っているときにデスクトップ通知を出す。
# BurntToast（トースト通知モジュール）が無ければ静かに終了する。
# 以前はフォールバックで MessageBox（モーダル）を開いていたが、OK を押すまで
# フックがブロックしてセッションが固まるため撤去した。通知が欲しい場合は
#   PowerShell で: Install-Module BurntToast -Scope CurrentUser
powershell.exe -Command "New-BurntToastNotification -Text 'Claude Code', 'Awaiting your input'" 2>/dev/null || true
exit 0
