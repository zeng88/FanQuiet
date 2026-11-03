# FanQuiet

FanQuiet 是一款面向 Intel MacBook 的轻量级进程检查工具。它的背景很直接：笔记本风扇持续高速运转时，用户需要快速找到 CPU 占用较高的应用或进程，再决定是否结束它。

FanQuiet 展示 CPU 使用率最高、且符合安全结束条件的进程，帮助排查高负载来源。它不会直接控制风扇或改变温控设置。

## 功能

- 显示 CPU 使用率最高的可结束进程，以及按 CPU 排序的前 15 项。
- 展示进程名称、PID、CPU、内存和运行时长。
- 未选择进程时每 5 秒刷新；选择一行后暂停自动刷新，方便稳定地操作。
- 刷新期间保留当前列表；点击“恢复并刷新”可取消选择并立即更新。
- 结束操作前显示确认框，并再次核对 PID、用户 ID、可执行路径和启动时间。
- 仅向当前用户的普通进程发送 `SIGTERM`，不会自动结束进程或发送 `SIGKILL`。

## 进程保护

FanQuiet 只展示当前用户且符合结束策略的进程。以下进程会隐藏并受到保护：

- PID 0、PID 1、root 用户或其他用户的进程。
- 可执行文件位于 `/System`、`/usr`、`/bin`、`/sbin` 或 `/private` 下的进程。
- WindowServer、loginwindow、launchd、kernel_task、Finder、Dock、SystemUIServer、coreaudiod 和 powerd 等关键进程。
- 路径无法验证，或在确认结束前身份发生变化的进程。

结束进程可能导致未保存的数据丢失。FanQuiet 不会请求管理员权限，不修改系统设置、风扇转速或电源管理，也不安装后台服务。

## 环境要求

- Intel Mac（x86_64）
- macOS 10.15 或更新版本；目标环境为 macOS 12
- Swift Command Line Tools
- 无第三方依赖；构建产物为本地未签名应用

## 构建与运行

在项目目录执行：

```sh
./self-test.sh
./build.sh
open dist/FanQuiet.app
```

自测脚本会编译并运行进程解析、展示过滤、保护策略和结束操作核验等测试。构建脚本会生成 `dist/FanQuiet.app`。
