# FanQuiet

FanQuiet 是面向 Intel MacBook 的轻量进程检查工具。打开后立即读取 CPU 进程快照，未选择进程时每 5 秒刷新，突出显示 CPU 使用率最高的可结束进程并列出前 15 项；选择一项后会暂停自动刷新，避免选中目标跳动。列表仅显示当前用户可结束的普通进程，系统及其他用户进程会隐藏。

## 构建与运行

```sh
./self-test.sh
./build.sh
open dist/FanQuiet.app
```

需要 macOS 与 Swift Command Line Tools。应用面向 x86_64，最低系统版本声明为 macOS 10.15；无第三方依赖，未签名。

## 结束进程规则

选择可操作的进程后，自动刷新暂停；点击“结束进程…”并在确认框中确认，或点击“恢复并刷新”取消选择并立即更新。应用只会向当前用户普通进程发送 `SIGTERM`，发送前再次核对 PID、UID、可执行路径和启动时间。PID 0/1、root/其他用户进程、`/System`、`/usr`、`/bin`、`/sbin`、`/private` 下的进程以及 WindowServer、loginwindow、launchd、kernel_task、Finder、Dock、SystemUIServer、coreaudiod、powerd 均受保护。应用不提权、不自动结束进程，也不会发送 `SIGKILL` 或更改风扇控制设置。
