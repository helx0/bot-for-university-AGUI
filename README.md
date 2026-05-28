# 🤖 University AGUI Bot

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Status](https://img.shields.io/badge/status-Active-brightgreen.svg)

تطبيق بوت ذكي مصمم لمساعدة الطلاب والأساتذة في جامعة AGUI من خلال الإجابة عن الاستفسارات الشائعة وتقديم المعلومات الأكاديمية.

## ✨ الميزات الرئيسية

- 🤖 **واجهة برمجية ذكية** للإجابة على الأسئلة
- 📚 **قاعدة معلومات شاملة** عن الجامعة والأقسام الأكاديمية
- ⚡ **استجابة سريعة** وفعالة
- 🌐 **دعم اللغة العربية** الكامل
- 👥 **واجهة سهلة الاستخدام** للطلاب والعاملين

## 🚀 البدء السريع

### المتطلبات
- Python 3.8+
- pip

### التثبيت

```bash
# استنساخ المستودع
git clone https://github.com/helx0/bot-for-university-AGUI.git
cd bot-for-university-AGUI

# تثبيت المتطلبات
pip install -r requirements.txt

# تشغيل البوت
python bot.py
```

## 📖 الاستخدام

```python
# مثال على الاستخدام الأساسي
from bot import UniversityBot

bot = UniversityBot()
response = bot.answer_question("متى موعد التسجيل؟")
print(response)
```

## 🏗️ البنية

```
bot-for-university-AGUI/
├── bot.py                 # الملف الرئيسي للبوت
├── data/                  # قاعدة البيانات
├── requirements.txt       # المتطلبات
└── README.md             # هذا الملف
```

## 🤝 المساهمة

نرحب بالمساهمات! يرجى:

1. عمل fork للمستودع
2. إنشاء فرع للميزة الجديدة (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push إلى الفرع (`git push origin feature/AmazingFeature`)
5. فتح Pull Request

## 📝 الترخيص

هذا المشروع مرخص تحت MIT License - انظر ملف [LICENSE](LICENSE) للتفاصيل.

## 📧 التواصل

للأسئلة والاقتراحات، يرجى فتح issue أو التواصل مباشرة.

---

**تم تطويره بـ ❤️ من قبل فريق التطوير**
