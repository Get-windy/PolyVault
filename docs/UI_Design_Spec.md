# PolyVault UI 设计规范

**版本**: 1.0  
**最后更新**: 2026-03-25  
**作者**: team-member

---

## 目录
1. [设计原则](#设计原则)
2. [色彩系统](#色彩系统)
3. [字体系统](#字体系统)
4. [组件规范](#组件规范)
5. [界面布局](#界面布局)
6. [动画效果](#动画效果)
7. [深色模式](#深色模式)

---

## 设计原则

### 一致性
- 所有界面元素遵循统一的设计语言
- 相同功能的组件在不同页面保持一致的外观和行为

### 简洁性
- 界面简洁清爽，避免过度装饰
- 专注于内容展示和功能使用

### 反馈
- 所有交互都有明确的视觉反馈
- 状态变化清晰可见

### 保护
- 安全相关操作有专门的视觉区分
- 敏感操作需要二次确认

---

## 色彩系统

### 主色调

| 名称 | 十六进制 | 用途 |
|------|----------|------|
| Primary | `#3B82F6` | 主要操作按钮、链接、图标 |
| Primary Dark | `#2563EB` | 按钮按下状态 |
| Primary Light | `#60A5FA` | 按钮悬停状态 |
| Secondary | `#10B981` | 成功状态、确认操作 |
| Tertiary | `#8B5CF6` | 第三色系、点缀色 |

### 语义颜色

| 名称 | 十六进制 | 用途 |
|------|----------|------|
| Success | `#22C55E` | 成功提示、绿色指标 |
| Error | `#EF4444` | 错误提示、警告颜色 |
| Warning | `#F59E0B` | 警告提示、黄色指标 |
| Info | `#3B82F6` | 信息提示、蓝色指标 |

### 背景色

| 名称 | 十六进制 | 用途 | 明暗 |
|------|----------|------|------|
| Background | `#F9FAFB` | 页面背景 | 浅色 |
| Surface | `#FFFFFF` | 容器背景 | 浅色 |
| Card | `#FFFFFF` | 卡片背景 | 浅色 |
| Background Dark | `#0F172A` | 页面背景 | 深色 |
| Surface Dark | `#1E293B` | 容器背景 | 深色 |
| Card Dark | `#2D3748` | 卡片背景 | 深色 |

### 文本色

| 名称 | 十六进制 | 用途 | 明暗 |
|------|----------|------|------|
| Text Primary | `#111827` | 主要文本 | 浅色 |
| Text Secondary | `#6B7280` | 次要文本 | 浅色 |
| Text Muted | `#9CA3AF` | 弱文本 | 浅色 |
| Text Primary Dark | `#F3F4F6` | 主要文本 | 深色 |
| Text Secondary Dark | `#9CA3AF` | 次要文本 | 深色 |
| Text Muted Dark | `#4B5563` | 弱文本 | 深色 |

### 渐变色

```dart
// 主色渐变
LinearGradient(
  colors: [Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF8B5CF6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)

// Secondary渐变
LinearGradient(
  colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

---

## 字体系统

### 标题样式

| 级别 | 字号 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| Display Large | 32px | 700 | 1.2 | 页面标题 |
| Display Medium | 28px | 600 | 1.25 | 大标题 |
| Display Small | 24px | 600 | 1.3 | 小标题 |
| Headline Large | 22px | 600 | 1.3 | 主要标题 |
| Headline Medium | 20px | 600 | 1.4 | 二级标题 |
| Headline Small | 18px | 500 | 1.4 | 三级标题 |

### 正文样式

| 级别 | 字号 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| Body Large | 16px | 400 | 1.5 | 大段落文本 |
| Body Medium | 14px | 400 | 1.5 | 正常段落文本 |
| Body Small | 12px | 400 | 1.5 | 小段落文本 |

### 其他样式

| 级别 | 字号 | 字重 | 字间距 | 用途 |
|------|------|------|--------|------|
| Button Large | 16px | 600 | 0.5 | 大按钮 |
| Button Medium | 14px | 600 | 0.3 | 正常按钮 |
| Button Small | 12px | 600 | 0.2 | 小按钮 |
| Caption | 12px | 400 | 1.4 | 说明文字 |
| Overline | 10px | 600 | 1.0 | 上标文字 |

---

## 组件规范

### 按钮组件

#### FilledButton (填充按钮)
- 背景色: `#3B82F6`
- 前景色: `#FFFFFF`
- 圆角: `12px`
- 内边距: `14px vertical, 24px horizontal`
- 阴影: `2px`

#### FilledTonalButton (填充变体按钮)
- 背景色: `#A78BFA` (15%透明度)
- 前景色: `#8B5CF6`
- 圆角: `12px`

#### OutlinedButton (描边按钮)
- 边框色: `#3B82F6`
- 前景色: `#3B82F6`
- 边框宽度: `1.5px`
- 圆角: `12px`

#### TextButton (文字按钮)
- 前景色: `#3B82F6`
- 内边距: `8px vertical, 16px horizontal`

### 输入框组件

- 圆角: `12px`
- 边框宽度: `1.5px`
- 悬浮边框色: `#3B82F6`
- 清晰边框色: `#9CA3AF`
- 内边距: `16px horizontal, 16px vertical`

### 卡片组件

- 圆角: `20px`
- 阴影: `4px blur, 2px offset`
- 边框: `1px solid #E5E7EB`
- 内边距: `20px`

### 分隔符

- 高度: `1px`
- 颜色: `#E5E7EB`
- 间距: `1px`

---

## 界面布局

### 页面结构

```
┌─────────────────────────────────┐
│  AppBar                         │
│  ┌───────────────────────────┐  │
│  │ ←  标题          选项   │  │
│  └───────────────────────────┘  │
├─────────────────────────────────┤
│                                 │
│  主内容区域                       │
│                                 │
├─────────────────────────────────┤
│                                 │
│  底部导航栏                       │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐      │
│  │图标│ │图标│ │图标│ │图标│      │
│  └───┘ └───┘ └───┘ └───┘      │
└─────────────────────────────────┘
```

### 间距系统

| 名称 | 尺寸 | 用途 |
|------|------|------|
| XS | 4px | 微小间距 |
| SM | 8px | 小间距 |
| MD | 16px | 中等间距 |
| LG | 24px | 大间距 |
| XL | 32px | 特大间距 |
| XXL | 48px | 超大间距 |

### 圆角系统

| 名称 | 尺寸 | 用途 |
|------|------|------|
| SM | 6px | 小圆角 |
| MD | 12px | 中等圆角 |
| LG | 20px | 大圆角 |
| XL | 28px | 特大圆角 |
| Full | 9999px | 完全圆角 |

---

## 动画效果

### 动画类型

#### 1. 淡入 (Fade In)
```dart
FadeIn(
  child: widget,
  duration: Duration(milliseconds: 500),
  curve: Curves.easeOut,
)
```

#### 2. 滑入 (Slide In)
```dart
SlideIn(
  child: widget,
  duration: Duration(milliseconds: 400),
  from: Offset(0, 1),
)
```

#### 3. 缩放 (Scale In)
```dart
ScaleIn(
  child: widget,
  duration: Duration(milliseconds: 400),
  from: 0.8,
)
```

#### 4. 弹跳 (Bounce In)
```dart
BounceIn(
  child: widget,
  duration: Duration(milliseconds: 600),
)
```

### 页面过渡动画

- 进入动画: `FadeTransition`, `Duration: 300ms`
- 退出动画: `FadeTransition`, `Duration: 300ms`
- 对话框: `FadeTransition`, `Duration: 300ms`

---

## 深色模式

### 与浅色模式的区别

| 元素 | 浅色模式 | 深色模式 |
|------|----------|----------|
| 背景 | `#F9FAFB` | `#0F172A` |
| 表面 | `#FFFFFF` | `#1E293B` |
| 卡片 | `#FFFFFF` | `#2D3748` |
| 文本 Primary | `#111827` | `#F3F4F6` |
| 文本 Secondary | `#6B7280` | `#9CA3AF` |
| 边框 | `#E5E7EB` | `#374151` |

### 深色模式特殊处理

1. **卡片阴影**: 深色模式下阴影更明显 (`#000000 0.1`)
2. **文字对比**: 确保深色模式下文字对比度足够
3. **颜色饱和度**: 适当降低深色模式下的颜色饱和度

---

## 组件使用示例

### 使用卡片组件
```dart
RoundedContainer(
  child: Column(
    children: [
      Text('卡片标题'),
      Text('卡片内容'),
    ],
  ),
  padding: const EdgeInsets.all(20),
  margin: const EdgeInsets.all(16),
  borderRadius: AppRadius.lg,
  shadow: AppColors.mediumShadow,
)
```

### 使用按钮组件
```dart
FilledButton(
  onPressed: () {},
  child: Text('按钮文本'),
)
```

### 使用动画组件
```dart
SlideIn(
  child: Container(
    color: Colors.blue,
    height: 100,
    width: double.infinity,
  ),
)
```

---

## 颜色 RGB 值参考

| 颜色 | R | G | B |
|------|---|---|---|
| Primary | 59 | 130 | 246 |
| Primary Dark | 37 | 99 | 235 |
| Primary Light | 96 | 165 | 250 |
| Secondary | 16 | 185 | 129 |
| Success | 34 | 197 | 94 |
| Error | 239 | 68 | 68 |
| Warning | 245 | 158 | 11 |
| Info | 59 | 130 | 246 |

---

## 附录

### 设计资源

- **Figma**: 需要联系设计师获取
- **Color Palette**: 参考 Tailwind CSS 颜色系统
- **Icon Pack**: Flutter Icons (Material Icons Extended)

### 参考资料

- [Material Design 3](https://m3.material.io/)
- [Flutter Theme System](https://docs.flutter.dev/ui/design-language)
- [Color System Guide](https://learnui.design/blog/material-design-color-palette.html)

---

**最后更新**: 2026-03-25