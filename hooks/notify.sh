#!/bin/bash
# カスタム通知 (Notification)
# Claude Code が入力を待っているときにデスクトップ通知を出す
powershell.exe -Command "New-BurntToastNotification -Text 'Claude Code', 'Awaiting your input'" 2>/dev/null ||
  powershell.exe -Command "[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Awaiting your input','Claude Code','OK','Information')" 2>/dev/null
exit 0
