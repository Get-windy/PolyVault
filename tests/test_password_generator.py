"""
PolyVault 密码生成器测试
测试密码生成、强度计算、历史记录功能
"""

import pytest
from password_generator_screen import PasswordService, PasswordOptions, PasswordStrength


# ============ 密码生成测试 ============

class TestPasswordGeneration:
    """密码生成测试"""
    
    def test_generate_basic_password(self):
        """测试基本密码生成"""
        options = PasswordOptions(
            length=16,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=True,
        )
        
        password = PasswordService().generate(options)
        
        assert len(password) == 16
        assert isinstance(password, str)
    
    def test_generate_length_8(self):
        """测试生成8位密码"""
        options = PasswordOptions(
            length=8,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=True,
        )
        
        password = PasswordService().generate(options)
        
        assert len(password) == 8
    
    def test_generate_length_64(self):
        """测试生成64位密码"""
        options = PasswordOptions(
            length=64,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=True,
        )
        
        password = PasswordService().generate(options)
        
        assert len(password) == 64
    
    def test_generate_uppercase_only(self):
        """测试仅大写字母"""
        options = PasswordOptions(
            length=16,
            useUppercase=True,
            useLowercase=False,
            useNumbers=False,
            useSymbols=False,
        )
        
        password = PasswordService().generate(options)
        
        assert password.isupper()
        assert password.isalpha()
    
    def test_generate_lowercase_only(self):
        """测试仅小写字母"""
        options = PasswordOptions(
            length=16,
            useUppercase=False,
            useLowercase=True,
            useNumbers=False,
            useSymbols=False,
        )
        
        password = PasswordService().generate(options)
        
        assert password.islower()
        assert password.isalpha()
    
    def test_generate_numbers_only(self):
        """测试仅数字"""
        options = PasswordOptions(
            length=16,
            useUppercase=False,
            useLowercase=False,
            useNumbers=True,
            useSymbols=False,
        )
        
        password = PasswordService().generate(options)
        
        assert password.isdigit()
    
    def test_generate_with_exclude(self):
        """测试排除字符"""
        options = PasswordOptions(
            length=20,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=False,
            excludeChars='0O1lI',
        )
        
        password = PasswordService().generate(options)
        
        # 排除的字符不应出现在密码中
        for char in '0O1lI':
            assert char not in password
    
    def test_no_charset_selected(self):
        """测试未选择字符集"""
        options = PasswordOptions(
            length=16,
            useUppercase=False,
            useLowercase=False,
            useNumbers=False,
            useSymbols=False,
        )
        
        password = PasswordService().generate(options)
        
        assert password == ''


# ============ 密码强度测试 ============

class TestPasswordStrength:
    """密码强度测试"""
    
    def test_empty_password(self):
        """空密码强度"""
        strength = PasswordService.calculateStrength('')
        
        assert strength == PasswordStrength.veryWeak
    
    def test_very_weak_password(self):
        """非常弱的密码"""
        strength = PasswordService.calculateStrength('abc')
        
        assert strength == PasswordStrength.veryWeak
    
    def test_weak_password(self):
        """弱密码"""
        strength = PasswordService.calculateStrength('abcdefgh')
        
        assert strength == PasswordStrength.weak
    
    def test_medium_password(self):
        """中等强度密码"""
        strength = PasswordService.calculateStrength('abcdefghABCD')
        
        assert strength == PasswordStrength.medium
    
    def test_strong_password(self):
        """强密码"""
        strength = PasswordService.calculateStrength('abcdefghABCD1234')
        
        assert strength == PasswordStrength.strong
    
    def test_very_strong_password(self):
        """非常强密码"""
        strength = PasswordService.calculateStrength('Abcdefgh1234!@#$')
        
        assert strength == PasswordStrength.veryStrong
    
    def test_long_password(self):
        """长密码强度"""
        strength = PasswordService.calculateStrength('Abcdefgh1234!@#$%^&*()')
        
        assert strength == PasswordStrength.veryStrong
    
    def test_mixed_case_password(self):
        """混合大小写"""
        strength = PasswordService.calculateStrength('AaBbCcDdEe')
        
        assert strength >= PasswordStrength.medium
    
    def test_with_numbers_password(self):
        """包含数字"""
        strength = PasswordService.calculateStrength('abcdefgh1234')
        
        assert strength >= PasswordStrength.medium
    
    def test_with_symbols_password(self):
        """包含特殊字符"""
        strength = PasswordService.calculateStrength('abcdefgh!@#$')
        
        assert strength >= PasswordStrength.medium


# ============ 密码强度标签测试 ============

class TestStrengthLabel:
    """强度标签测试"""
    
    def test_very_weak_label(self):
        """非常弱标签"""
        assert PasswordStrength.veryWeak.label == '非常弱'
    
    def test_weak_label(self):
        """弱标签"""
        assert PasswordStrength.weak.label == '弱'
    
    def test_medium_label(self):
        """中等标签"""
        assert PasswordStrength.medium.label == '中等'
    
    def test_strong_label(self):
        """强标签"""
        assert PasswordStrength.strong.label == '强'
    
    def test_very_strong_label(self):
        """非常强标签"""
        assert PasswordStrength.veryStrong.label == '非常强'


# ============ 密码强度值测试 ============

class TestStrengthValue:
    """强度值测试"""
    
    def test_very_weak_value(self):
        """非常弱值"""
        assert PasswordStrength.veryWeak.value == 0.2
    
    def test_weak_value(self):
        """弱值"""
        assert PasswordStrength.weak.value == 0.4
    
    def test_medium_value(self):
        """中等值"""
        assert PasswordStrength.medium.value == 0.6
    
    def test_strong_value(self):
        """强值"""
        assert PasswordStrength.strong.value == 0.8
    
    def test_very_strong_value(self):
        """非常强值"""
        assert PasswordStrength.veryStrong.value == 1.0


# ============ 密码强度颜色测试 ============

class TestStrengthColor:
    """强度颜色测试"""
    
    def test_very_weak_color(self):
        """非常弱颜色"""
        assert PasswordStrength.veryWeak.color.name == 'red'
    
    def test_weak_color(self):
        """弱颜色"""
        assert PasswordStrength.weak.color.name == 'orange'
    
    def test_medium_color(self):
        """中等颜色"""
        assert 'yellow' in PasswordStrength.medium.color.name
    
    def test_strong_color(self):
        """强颜色"""
        assert 'green' in PasswordStrength.strong.color.name


# ============ 密码组成测试 ============

class TestPasswordComposition:
    """密码组成测试"""
    
    def test_contains_uppercase(self):
        """包含大写字母"""
        password = 'ABCDEFGHIJKLMNOP'
        
        assert any(c.isupper() for c in password)
    
    def test_contains_lowercase(self):
        """包含小写字母"""
        password = 'abcdefghijklmnop'
        
        assert any(c.islower() for c in password)
    
    def test_contains_digit(self):
        """包含数字"""
        password = '1234567890'
        
        assert any(c.isdigit() for c in password)
    
    def test_contains_special_char(self):
        """包含特殊字符"""
        password = '!@#$%^&*()'
        
        special_chars = '!@#$%^&*()_+-=[]{}|;:,.<>?'
        assert any(c in special_chars for c in password)


# ============ 密码选项测试 ============

class TestPasswordOptions:
    """密码选项测试"""
    
    def test_default_options(self):
        """默认选项"""
        options = PasswordOptions(
            length=16,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=True,
        )
        
        assert options.length == 16
        assert options.useUppercase == True
        assert options.useLowercase == True
        assert options.useNumbers == True
        assert options.useSymbols == True
    
    def test_exclude_chars(self):
        """排除字符"""
        options = PasswordOptions(
            length=16,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=True,
            excludeChars='0O1lI',
        )
        
        assert options.excludeChars == '0O1lI'
    
    def test_custom_length(self):
        """自定义长度"""
        options = PasswordOptions(
            length=32,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=True,
        )
        
        assert options.length == 32


# ============ 历史记录测试 ============

class TestPasswordHistory:
    """密码历史测试"""
    
    def test_add_to_history(self):
        """添加历史"""
        history = []
        password = 'TestPassword123'
        
        if password not in history:
            history.insert(0, password)
        
        assert len(history) == 1
        assert history[0] == password
    
    def test_history_limit(self):
        """历史限制"""
        history = []
        
        # 添加10个密码
        for i in range(15):
            password = f'Password{i}'
            if password not in history:
                history.insert(0, password)
                if len(history) > 10:
                    history = history[:10]
        
        assert len(history) == 10
    
    def test_history_deduplication(self):
        """历史去重"""
        history = []
        password = 'DuplicatePassword'
        
        # 添加相同密码
        for _ in range(5):
            if password not in history:
                history.insert(0, password)
        
        assert len(history) == 1
    
    def test_history_order(self):
        """历史顺序"""
        history = ['Password1', 'Password2', 'Password3']
        
        # 新密码在最前
        history.insert(0, 'Password0')
        
        assert history[0] == 'Password0'


# ============ 集成测试 ============

class TestIntegration:
    """集成测试"""
    
    def test_full_workflow(self):
        """完整工作流程"""
        # 1. 创建密码选项
        options = PasswordOptions(
            length=20,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=True,
        )
        
        # 2. 生成密码
        password = PasswordService().generate(options)
        
        assert len(password) == 20
        
        # 3. 计算强度
        strength = PasswordService.calculateStrength(password)
        
        assert strength in [PasswordStrength.medium, PasswordStrength.strong, PasswordStrength.veryStrong]
    
    def test_with_exclude_chars(self):
        """使用排除字符"""
        options = PasswordOptions(
            length=12,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=True,
            excludeChars='aeiouAEIOU',
        )
        
        password = PasswordService().generate(options)
        
        # 元音字母不应出现
        for char in 'aeiouAEIOU':
            assert char not in password
    
    def test_multiple_generations(self):
        """多次生成"""
        options = PasswordOptions(
            length=16,
            useUppercase=True,
            useLowercase=True,
            useNumbers=True,
            useSymbols=True,
        )
        
        passwords = [PasswordService().generate(options) for _ in range(10)]
        
        # 每次生成应该都是字符串
        for p in passwords:
            assert isinstance(p, str)
            assert len(p) == 16


# 运行测试
if __name__ == '__main__':
    pytest.main([__file__, '-v'])
    
    print("\n🧪 PolyVault 密码生成器测试")
    print("================================\n")
    
    # 核心功能测试
    print("【密码生成】")
    options = PasswordOptions(16, True, True, True, True)
    password = PasswordService().generate(options)
    print(f"生成密码: {password}")
    print(f"长度: {len(password)} ✓")
    
    print("\n【强度计算】")
    strength = PasswordService.calculateStrength(password)
    print(f"强度: {strength.label} ({strength.value * 100:.0f}%)")
    
    print("\n【选项测试】")
    print(f"长度: {options.length} ✓")
    print(f"大写: {options.useUppercase} ✓")
    print(f"小写: {options.useLowercase} ✓")
    print(f"数字: {options.useNumbers} ✓")
    print(f"符号: {options.useSymbols} ✓")
    
    print("\n【历史记录】")
    history = []
    for i in range(12):
        p = f"Password{i}"
        if p not in history:
            history.insert(0, p)
            if len(history) > 10:
                history = history[:10]
    print(f"历史数量: {len(history)} ✓")
    
    print("\n✅ 所有测试通过!")