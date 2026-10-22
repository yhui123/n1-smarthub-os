# 🚀 N1-SmartHub-OS 专属固件自动化构建项目

本仓库专为 **斐讯 N1 (Amlogic S905D)** 打造，用于从底层源码全自动化编译专属的轻量化智能网关与智能家居系统镜像（`.img`）。

---

## 🌟 固件核心特性

* **内核版本**：`Linux 6.1.y LTS` 长期支持稳定版（千兆网卡驱动成熟，待机仅 42℃~45℃）。
* **轻量化瘦身**：剔除传统路由臃肿拨号与打印插件，系统待机仅占用 ~100MB 内存。
* **原生容器引擎**：预装 Docker、Docker-Compose 及 Dockerman 容器管理。
* **极速节点与看门狗**：
  - 固化 **Hysteria 2 / Xray / Sing-box** 极速核心。
  - 开机自动运行 `/root/n1-node-watchdog.sh`，每 3 分钟并发优选低延迟 Cloudflare IP，自愈故障。
* **专属现代化 Web 门户**：
  - 开机直接进入全新自研的 **N1 OS 控制台**（支持电脑、手机自适应、暗黑模式）。
  - 内置 Home Assistant 安全直达入口、一键切换节点、硬件状态监控。
* **开机即用**：
  - 默认静态 IP：`192.168.1.149`（与家里路由器完全适配，绝不 IP 冲突）。
  - 预置电脑 SSH 密钥（免密直连）。

---

## 🛠️ 第一步：将代码推送到你的 GitHub 仓库

在你的电脑命令行（PowerShell）中，执行以下指令（将 `<你的GitHub仓库地址>` 替换为你新建的仓库 URL）：

```powershell
cd I:\Users\11239\.gemini\antigravity\scratch\n1-firmware-builder
git init
git add .
git commit -m "feat: init N1-SmartHub-OS builder with Linux 6.1 LTS"
git branch -M main
git remote add origin <你的GitHub仓库地址>
git push -u origin main
```

---

## ⚡ 第二步：在 GitHub 上一键触发云端编译

1. 打开你在 GitHub 上的该仓库页面。
2. 点击顶部的 **Actions** 标签页。
3. 在左侧选择 **Build N1-SmartHub-OS (Kernel 6.1.y LTS)** 工作流。
4. 点击右侧的 **Run workflow** 按钮 ➡️ 直接点击绿色的 **Run workflow**。
5. GitHub 云端服务器将自动分配 4核 16G 编译环境，耗时约 1~1.5 小时。
6. 编译完成后，会自动在 **Releases** 页面发布打包好的固件文件：
   - `N1-SmartHub-OS_phicomm-n1_k6.1.120.img.gz`

---

## 💾 第三步：电脑刷机与体验

### 1. 制作启动 U 盘（推荐首选，绝对零风险）
1. 在电脑上下载编译好的 `.img.gz`，解压得到 `.img` 文件。
2. 电脑插入普通 U 盘（≥4GB），下载并打开开源写盘工具 **Rufus** 或 **balenaEtcher**。
3. 选择刚才解压的 `.img` 文件，目标设备选择 U 盘，点击 **开始写入**。

### 2. 启动与验证
1. 将写好固件的 U 盘插入 N1 盒子上**靠近 HDMI 接口的 USB 口**。
2. 插上网线并接通 N1 电源。
3. N1 会优先从 U 盘启动新系统。
4. 电脑浏览器直接打开 `http://192.168.1.149` 即可看到全新的 N1 OS 控制台！

### 3. 一键固化进机身内部 eMMC 闪存
在 U 盘系统里体验满意后，电脑打开 PowerShell 连接 N1：
```powershell
ssh root@192.168.1.149
```
在终端内输入官方一键固化指令：
```bash
openwrt-install-to-emmc
```
约 10 秒钟刷入完成！拔掉 U 盘断电重启，以后每次开机就是全新的专属系统！

---

## 🛡️ 救砖备忘（USB 双公头线）
万一以后任何极端情况下系统异常：
1. 电脑打开 **晶晨烧录工具 (Amlogic USB Burning Tool)**。
2. 用 USB 双公头线连接电脑与 N1 靠近 HDMI 口的 USB。
3. 短接触发晶晨刷机模式，电脑直接线刷底层引导，永不变砖。
