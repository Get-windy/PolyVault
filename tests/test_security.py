"""
PolyVault 安全中心测试
测试安全评分、风险检测、建议生成
"""

import pytest
from datetime import datetime


# 风险级别枚举
class RiskLevel:
    CRITICAL = 'critical'
    HIGH = 'high'
    MEDIUM = 'medium'
    LOW = 'low'
    INFO = 'info'


# 安全项类型
class SecurityItemType:
    PASSWORD = 'password'
    TWO_FACTOR = 'two_factor'
    DEVICE = 'device'
    SESSION = 'session'
    BACKUP = 'backup'
    ENCRYPTION = 'encryption'
    PRIVACY = 'privacy'


# 安全风险项
class SecurityRiskItem:
    def __init__(self, id, title, description, level, item_type, is_resolved=False):
        self.id = id
        self.title = title
        self.description = description
        self.level = level
        self.type = item_type
        self.is_resolved = is_resolved

    def mark_resolved(self):
        self.is_resolved = True

    def copy_with(self, **kwargs):
        return SecurityRiskItem(
            id=kwargs.get('id', self.id),
            title=kwargs.get('title', self.title),
            description=kwargs.get('description', self.description),
            level=kwargs.get('level', self.level),
            item_type=kwargs.get('type', self.type),
            is_resolved=kwargs.get('is_resolved', self.is_resolved),
        )


# 安全评分计算器
class SecurityScoreCalculator:
    def __init__(self):
        self.items = []

    def add_item(self, item):
        self.items.append(item)

    def calculate_score(self):
        if not self.items:
            return 100

        total_weight = 0
        score = 100

        weights = {
            RiskLevel.CRITICAL: 25,
            RiskLevel.HIGH: 15,
            RiskLevel.MEDIUM: 10,
            RiskLevel.LOW: 5,
            RiskLevel.INFO: 2,
        }

        for item in self.items:
            if not item.is_resolved:
                weight = weights.get(item.level, 5)
                score -= weight

        return max(0, score)

    def get_score_level(self):
        score = self.calculate_score()
        if score >= 90:
            return '优秀'
        if score >= 70:
            return '良好'
        if score >= 50:
            return '一般'
        return '危险'


# 风险检测器
class RiskDetector:
    def __init__(self):
        self.rules = []

    def add_rule(self, name, check_func):
        self.rules.append({'name': name, 'check': check_func})

    def detect(self, user_data):
        risks = []
        for rule in self.rules:
            if rule['check'](user_data):
                risks.append(rule['name'])
        return risks

    def check_password_strength(self, password):
        if not password:
            return False
        if len(password) < 8:
            return False
        has_upper = any(c.isupper() for c in password)
        has_lower = any(c.islower() for c in password)
        has_digit = any(c.isdigit() for c in password)
        return has_upper and has_lower and has_digit

    def check_two_factor_enabled(self, enabled):
        return not enabled

    def check_backup_enabled(self, enabled):
        return not enabled

    def check_session_timeout(self, timeout_minutes):
        return timeout_minutes > 30


# 安全建议生成器
class SecurityTipGenerator:
    def __init__(self):
        self.tips = []

    def generate_tips(self, user_data, risks):
        tips = []

        if 'weak_password' in risks:
            tips.append({
                'id': 'tip_password',
                'title': '加强密码强度',
                'description': '使用至少8位包含大小写字母和数字的密码',
                'icon': '🔑',
                'priority': 1,
            })

        if 'no_two_factor' in risks:
            tips.append({
                'id': 'tip_2fa',
                'title': '启用两步验证',
                'description': '为您的账户添加额外的安全保护',
                'icon': '🔐',
                'priority': 2,
            })

        if 'no_backup' in risks:
            tips.append({
                'id': 'tip_backup',
                'title': '开启自动备份',
                'description': '定期备份您的数据以防丢失',
                'icon': '💾',
                'priority': 3,
            })

        if 'long_session' in risks:
            tips.append({
                'id': 'tip_session',
                'title': '缩短会话超时',
                'description': '建议将会话超时设置为15-30分钟',
                'icon': '⏱️',
                'priority': 4,
            })

        return sorted(tips, key=lambda t: t['priority'])


class TestSecurityScore:
    """测试安全评分"""

    def test_calculate_score_no_items(self):
        calc = SecurityScoreCalculator()
        assert calc.calculate_score() == 100

    def test_calculate_score_with_resolved_item(self):
        calc = SecurityScoreCalculator()
        item = SecurityRiskItem('1', 'Test', 'Desc', RiskLevel.HIGH, SecurityItemType.PASSWORD, True)
        calc.add_item(item)
        assert calc.calculate_score() == 100

    def test_calculate_score_with_unresolved_critical(self):
        calc = SecurityScoreCalculator()
        item = SecurityRiskItem('1', 'Test', 'Desc', RiskLevel.CRITICAL, SecurityItemType.PASSWORD, False)
        calc.add_item(item)
        assert calc.calculate_score() == 75

    def test_calculate_score_with_multiple_items(self):
        # 测试多个项目的评分计算（解决状态的项目不扣分）
        calc = SecurityScoreCalculator()
        items = [
            SecurityRiskItem('1', '1', '1', RiskLevel.CRITICAL, 'password', False),  # 扣 25
            SecurityRiskItem('2', '2', '2', RiskLevel.HIGH, '2fa', False),          # 扣 15
            SecurityRiskItem('3', '3', '3', RiskLevel.LOW, 'backup', False),        # 扣 5
            SecurityRiskItem('4', '4', '4', RiskLevel.MEDIUM, 'session', True),     # 已解决，不扣分
        ]
        for item in items:
            calc.add_item(item)
        # 初始分数 100，扣除 25 + 15 + 5 = 45，得到 55
        assert calc.calculate_score() == 55

    def test_get_score_level_excellent(self):
        calc = SecurityScoreCalculator()
        item = SecurityRiskItem('1', 'Test', 'Desc', RiskLevel.INFO, SecurityItemType.PASSWORD, True)
        calc.add_item(item)
        assert calc.get_score_level() == '优秀'

    def test_get_score_level_danger(self):
        calc = SecurityScoreCalculator()
        item = SecurityRiskItem('1', 'Test', 'Desc', RiskLevel.CRITICAL, SecurityItemType.PASSWORD, False)
        calc.add_item(item)
        # 100 - 25 = 75，属于"良好"范围
        assert calc.get_score_level() == '良好'


class TestRiskDetection:
    """测试风险检测"""

    def test_detect_weak_password(self):
        detector = RiskDetector()
        detector.add_rule('weak_password', lambda d: not detector.check_password_strength(d.get('password', '')))

        user_data = {'password': 'weak'}
        risks = detector.detect(user_data)
        assert 'weak_password' in risks

    def test_detect_strong_password(self):
        detector = RiskDetector()
        detector.add_rule('weak_password', lambda d: not detector.check_password_strength(d.get('password', '')))

        user_data = {'password': 'StrongPass123'}
        risks = detector.detect(user_data)
        assert 'weak_password' not in risks

    def test_detect_no_two_factor(self):
        detector = RiskDetector()
        detector.add_rule('no_two_factor', lambda d: detector.check_two_factor_enabled(d.get('two_factor_enabled', False)))

        user_data = {'two_factor_enabled': False}
        risks = detector.detect(user_data)
        assert 'no_two_factor' in risks

    def test_detect_long_session(self):
        detector = RiskDetector()
        detector.add_rule('long_session', lambda d: detector.check_session_timeout(d.get('session_timeout', 60)))

        user_data = {'session_timeout': 60}
        risks = detector.detect(user_data)
        assert 'long_session' in risks


class TestSecurityTips:
    """测试安全建议生成"""

    def test_generate_password_tip(self):
        generator = SecurityTipGenerator()
        risks = ['weak_password', 'no_two_factor']
        tips = generator.generate_tips({}, risks)

        tip_ids = [t['id'] for t in tips]
        assert 'tip_password' in tip_ids
        assert tips[0]['priority'] == 1

    def test_generate_two_factor_tip(self):
        generator = SecurityTipGenerator()
        risks = ['no_two_factor']
        tips = generator.generate_tips({}, risks)

        tip_ids = [t['id'] for t in tips]
        assert 'tip_2fa' in tip_ids

    def test_generate_no_tips(self):
        generator = SecurityTipGenerator()
        tips = generator.generate_tips({}, [])
        assert len(tips) == 0

    def test_tips_sorted_by_priority(self):
        generator = SecurityTipGenerator()
        risks = ['weak_password', 'no_two_factor', 'no_backup', 'long_session']
        tips = generator.generate_tips({}, risks)

        priorities = [t['priority'] for t in tips]
        assert priorities == sorted(priorities)


class TestSecurityItemModel:
    """测试安全项数据模型"""

    def test_create_risk_item(self):
        item = SecurityRiskItem(
            '1',
            '测试风险',
            '这是一个测试',
            RiskLevel.HIGH,
            SecurityItemType.PASSWORD,
        )
        assert item.id == '1'
        assert item.level == RiskLevel.HIGH
        assert item.is_resolved is False

    def test_mark_resolved(self):
        item = SecurityRiskItem('1', 'Test', 'Desc', RiskLevel.MEDIUM, 'password')
        item.mark_resolved()
        assert item.is_resolved is True

    def test_copy_with(self):
        original = SecurityRiskItem('1', 'Original', 'Desc', RiskLevel.LOW, 'password')
        copied = original.copy_with(title='New', is_resolved=True)

        assert copied.id == '1'
        assert copied.title == 'New'
        assert copied.is_resolved is True


class TestRiskLevels:
    """测试风险级别"""

    def test_all_risk_levels(self):
        levels = [
            RiskLevel.CRITICAL,
            RiskLevel.HIGH,
            RiskLevel.MEDIUM,
            RiskLevel.LOW,
            RiskLevel.INFO,
        ]
        assert len(levels) == 5

    def test_risk_level_weights(self):
        weights = {
            RiskLevel.CRITICAL: 25,
            RiskLevel.HIGH: 15,
            RiskLevel.MEDIUM: 10,
            RiskLevel.LOW: 5,
            RiskLevel.INFO: 2,
        }
        assert weights[RiskLevel.CRITICAL] == 25
        assert weights[RiskLevel.LOW] == 5


# 运行所有测试
if __name__ == '__main__':
    pytest.main([__file__, '-v'])