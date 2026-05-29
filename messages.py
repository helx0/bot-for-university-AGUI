# 💬 الرسائل والنصوص
"""
تجميع جميع الرسائل والنصوص في ملف واحد
يوفر سهولة في التعديل والترجمة
"""

# ============ رسائل الترحيب ============

def get_welcome_message(user_first_name: str) -> str:
    """رسالة الترحيب الرئيسية"""
    return f"""
🎓 **مرحباً بك {user_first_name} في بوت جامعة تكنولوجيا المعلومات!**

🤖 **ماذا يمكنني أن أفعل لك:**

• 📚 **تصفح جميع المواد الدراسية**
• 🔍 **البحث في المحاضرات والملازم**
• 📖 **تحميل الملفات الدراسية**
• ⭐ **تقييم المواد والمحاضرات**
• 🏫 **تنظيم المحتوى حسب الفصول**

**اختر من الخيارات أدناه للبدء 👇**
    """


# ============ رسائل المواد الدراسية ============

def get_courses_message() -> str:
    """رسالة اختيار المواد"""
    return "📚 **المواد الدراسية المتاحة:**\n\naختر المادة التي تريد استعراض محتواها:"


def get_years_message(course_name: str) -> str:
    """رسالة اختيار السنة الدراسية"""
    return f"""
🏫 **{course_name}**

اختر السنة الدراسية:
✅ = يوجد محتوى
❌ = لا يوجد محتوى بعد
    """


def get_material_types_message(course_name: str, year: int) -> str:
    """رسالة اختيار نوع المادة"""
    return f"""
📁 **{course_name} - السنة {year}**

اختر نوع المادة التي تريد تصفحها:
    """


def get_materials_list_message(course_name: str, year: int, material_type_name: str, materials_text: str) -> str:
    """رسالة قائمة الملفات"""
    return f"""
📂 **{course_name} - السنة {year}**
📁 **{material_type_name}**

{materials_text}
    """


# ============ رسائل البحث ============

def get_search_help_message() -> str:
    """رسالة توضيح البحث المتقدم"""
    return """
🔍 **الباحث المتقدم**

اكتب كلمة البحث مع عوامل التصفية الاختيارية:

**أمثلة:**
`برمجة` - بحث في جميع المواد
`برمجة سنة:1` - بحث في السنة الأولى فقط
`شبكات نوع:محاضرة` - بحث في المحاضرات فقط
`قواعد بيانات سنة:2 نوع:ملزمة` - بحث متقدم

**عوامل التصفية:**
• `سنة:` - 1, 2, 3, 4
• `نوع:` - محاضرة, ملزمة, شرح, ملخص, امتحان

**الأنواع بالعربية:**
- محاضرة = lecture
- ملزمة = lab
- شرح = explanation
- ملخص = summary
- امتحان = exam
    """


def get_search_results_message(results_text: str) -> str:
    """رسالة نتائج البحث"""
    return f"🔍 **نتائج البحث:**\n\n{results_text}"


def get_no_search_results() -> str:
    """رسالة عدم وجود نتائج بحث"""
    return "❌ لم يتم العثور على نتائج تطابق بحثك."


# ============ رسائل التحميل ============

def get_download_caption(title: str, course_name: str, year: int, material_type: str) -> str:
    """عنوان الملف المحمل"""
    return f"""
📥 **{title}**

📚 المادة: {course_name}
🏫 السنة: {year}
📁 النوع: {material_type}

✅ تم التحميل بنجاح!
    """


def get_download_success_message() -> str:
    """رسالة نجاح التحميل"""
    return "💬 هل تريد تقييم هذا الملف؟"


# ============ رسائل الإدارة ============

def get_admin_panel_message(total_materials: int, total_courses: int, total_downloads: int) -> str:
    """رسالة لوحة تحكم المشرفين"""
    return f"""
🛠️ **لوحة تحكم المشرفين**

📊 **إحصائيات سريعة:**
• 📁 إجمالي الملفات: {total_materials}
• 📚 عدد المواد: {total_courses}
• 📥 إجمالي التحميلات: {total_downloads}

**اختر من الخيارات:**
    """


# ============ رسائل الرفع ============

def get_upload_course_message() -> str:
    """رسالة اختيار مادة للرفع"""
    return """
📤 **رفع ملف جديد**

اختر المادة:
    """


def get_upload_year_message(course_name: str) -> str:
    """رسالة اختيار سنة للرفع"""
    return f"""
🏫 **{course_name}**

اختر السنة الدراسية:
    """


def get_upload_type_message() -> str:
    """رسالة اختيار نوع المادة للرفع"""
    return "📁 اختر نوع المادة:"


def get_upload_title_message(course_name: str, year: int, material_type_name: str) -> str:
    """رسالة إدخال عنوان الملف"""
    return f"""
📤 **تفاصيل الرفع:**

📚 المادة: {course_name}
🏫 السنة: {year}
📁 النوع: {material_type_name}

✏️ **الآن أرسل عنوان الملف:**
(مثال: 'محاضرة 1 - المدخل إلى البرمجة')
    """


def get_upload_description_message() -> str:
    """رسالة إدخال وصف الملف"""
    return """
📝 **أرسل وصفاً للملف (اختياري):**
(اضغط /skip لتخطي هذه الخطوة)
    """


def get_upload_file_message(course_name: str, year: int, material_type_name: str, title: str, description: str) -> str:
    """��سالة إدخال الملف"""
    return f"""
📤 **تفاصيل الرفع:**

📚 المادة: {course_name}
🏫 السنة: {year}
📁 النوع: {material_type_name}
📄 العنوان: {title}
📝 الوصف: {description if description else 'لا يوجد'}

📎 **الآن أرسل الملف:**
(يمكنك إرسال ملف PDF، صورة، أو مستند)
    """


def get_upload_success_message() -> str:
    """رسالة نجاح الرفع"""
    return """
✅ **تم رفع الملف بنجاح!**

يمكنك متابعة رفع الملفات أو العودة للقائمة الرئيسية.
    """


# ============ رسائل الإحصائيات ============

def get_statistics_message(
    total_materials: int,
    total_courses: int,
    total_downloads: int,
    total_ratings: int,
    popular_courses_text: str,
    recent_files_text: str,
) -> str:
    """رسالة الإحصائيات"""
    return f"""
📊 **إحصائيات البوت**

📈 **إحصائيات عامة:**
• 📁 إجمالي الملفات: {total_materials}
• 📚 عدد المواد: {total_courses}
• 📥 إجمالي التحميلات: {total_downloads}
• ⭐ إجمالي التقييمات: {total_ratings}

🏆 **المواد الأكثر نشاطاً:**
{popular_courses_text}

🆕 **أحدث الملفات:**
{recent_files_text}
    """


# ============ رسائل الأخطاء ============

ERROR_MESSAGES = {
    "unauthorized": "❌ ليس لديك صلاحية الدخول هنا.",
    "no_materials": "❌ لا توجد مواد دراسية متاحة حالياً.",
    "no_file": "❌ الملف غير موجود.",
    "invalid_title": "❌ يرجى إرسال عنوان صحيح.",
    "invalid_file": "❌ يرجى إرسال ملف أو صورة.",
    "file_error": "❌ حدث خطأ في إرسال الملف.",
    "empty_search": "❌ يرجى إدخال كلمة البحث.",
    "no_results": "❌ لم يتم العثور على نتائج.",
    "unknown_command": "❌ لم أفهم طلبك.\nاستخدم الأزرار أو أرسل /start للبدء.",
}


# ============ رسائل الإجابات ============

INFO_MESSAGES = {
    "classes": """
🏫 **الفصول الدراسية**

استخدم خيار 'المواد الدراسية' لتصفح المحتوى حسب الفصول.
    """,
    "ratings": """
⭐ **نظام التقييمات**

سيتم تفعيل نظام التقييمات قريباً!
    """,
    "help": """
👤 **مساعدة واستفسارات**

للأسئلة والاستفسارات:
📧 البريد: support@university.edu
📞 الهاتف: 0123456789

لتطوير البوت أو الإبلاغ عن مشاكل:
@username
    """,
}
