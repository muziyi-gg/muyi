# 听股通 · 版本管理规范

## 版本号规则

格式：`主版本.次版本.修订号`

- **主版本 (Major)**：不兼容的重大功能重构
- **次版本 (Minor)**：新增功能（向后兼容）
- **修订号 (Patch)**：Bug 修复、小优化

示例：`v1.0.0` / `v1.1.0` / `v1.0.1`

---

## 开发分支

```
main          ← 生产环境代码（稳定版本）
     ↑
dev           ← 开发中功能（合并到 main 之前）
     ↑
feature/xxx   ← 具体功能分支（开发完成后合并 dev）
```

---

## 发版流程

```
1. 在本地 dev 分支完成开发
2. 提交代码：git add . && git commit -m "描述"
3. 推送：git push origin dev
4. 确认功能完成后，打 Tag：
   git tag -a v1.0.0 -m "版本 v1.0.0 说明"
   git push origin v1.0.0
5. GitHub Actions 自动构建 APK
6. 构建完成后在 GitHub Releases 下载 APK
```

---

## 每次 Tag 推送会自动触发

- GitHub Actions 编译 debug APK
- APK 自动上传到 Releases
- 版本号作为 Tag 名称

---

## 历史版本

| 版本 | 日期 | 说明 | APK |
|------|------|------|-----|
| v0.1.0 | 2026-04-07 | MVP Phase 1 Demo 框架，34个Dart文件，~3400行代码，包含播报调度器核心、11种播报类型、东方财富WebSocket接口 | 待构建 |
