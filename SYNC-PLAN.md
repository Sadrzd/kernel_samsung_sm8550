# Sadrzd/kernel_samsung_sm8550 — 同步方案（已准备好，待 Fork 完成后推入仓库）

来源：yucca-a/kernel_samsung_sm8550，main，3d7426bae42d910b5fd943f3c48df05a0c3b91f0
当前版本：Linux 5.15.224，LKM-only
特性：全部保留，包括 ipset（CONFIG_IP_SET / CONFIG_NETFILTER_XT_SET，build.sh 的检查不动）

## 为什么不能点 GitHub 的 Sync fork
yucca-a 不是 Fork，是手工拼装的，GitHub 上没有记录上游。直接 merge 三星
common 会是 unrelated history，会搞乱整棵树。

## 同步顺序（每周一 03:00 UTC 自动跑，也可手动触发）
1. 合 yucca-a 的新提交：共享历史，可安全 merge；冲突就停下来开 PR 人工解。
2. 试 kernel.org 下一个 LTS 增量补丁（如 5.15.224 -> 225）：下载
   patch-5.15.224-225.xz，验 SHA-256，`git apply --3way`，合不上就停下，
   不动 main。
3. 三星 common（samsung-sm8550/kernel_samsung_sm8550-common，android13-5.15）：
   只列出新提交供人工评审，不自动合。基线快照见 CREDITS-LINEAGE.md：
   26ae68f5ff6f12d396b3b26d4ab5ef72e7332514。

## 安全规则
- 同步只开 PR，从不 force-push main。
- 合完跑 ./build.sh --check、test_build_entry.py、test_feature_integration.sh，
  以及 Documentation/lts-update-20261101.md 里记的 vendor ABI 检查
  （2978 个符号 CRC、85 个结构布局）。
- 每次 LTS 升级仍可能要在 drivers/rekernel、gki_defconfig、mm、net 等
  特性文件上手动解冲突，这是正常的。

## 待办（Fork 完成后）
1. 把 .github/workflows/upstream-sync.yml 和 .github/scripts/try-next-lts-patch.sh
   推到 Sadrzd/kernel_samsung_sm8550 的 main。
2. 在 GitHub App 安装页把新仓库加进来，否则 Muse 的 GitHub 工具读不到它。
3. 手动跑一次 workflow_dispatch 验证。
