# 🎹 لوحات المفاتيح وأزرار البوت
"""
تجميع جميع لوحات المفاتيح والأزرار في ملف واحد
سهل الصيانة والتعديل
"""

from telegram import ReplyKeyboardMarkup, InlineKeyboardMarkup, InlineKeyboardButton


def get_main_keyboard() -> ReplyKeyboardMarkup:
    """لوحة المفاتيح الرئيسية للمستخدم العادي"""
    buttons = [
        ["📚 المواد الدراسية", "🔍 بحث متقدم"],
        ["🏫 الفصول الدراسية", "⭐ التقييمات"],
        ["📊 الإحصائيات", "👤 المساعدة"],
    ]
    return ReplyKeyboardMarkup(buttons, resize_keyboard=True)


def get_admin_keyboard() -> ReplyKeyboardMarkup:
    """لوحة المفاتيح الخاصة بالمشرفين"""
    buttons = [
        ["🛠️ لوحة التحكم", "📤 رفع ملف"],
        ["📊 إحصائيات", "👥 إدارة المشرفين"],
        ["🔙 القائمة الرئيسية"],
    ]
    return ReplyKeyboardMarkup(buttons, resize_keyboard=True)


def get_courses_keyboard(courses: list) -> InlineKeyboardMarkup:
    """لوحة أزرار المواد الدراسية"""
    buttons = []
    for course_id, name, code, _ in courses:
        button_text = f"{name} ({code})"
        buttons.append([InlineKeyboardButton(button_text, callback_data=f"course_{course_id}")])

    buttons.extend([
        [InlineKeyboardButton("🔍 بحث في جميع المواد", callback_data="search_all")],
        [InlineKeyboardButton("📊 المواد الأكثر نشاطاً", callback_data="popular_courses")],
    ])

    return InlineKeyboardMarkup(buttons)


def get_years_keyboard(course_id: int, available_years: list) -> InlineKeyboardMarkup:
    """لوحة أزرار السنوات الدراسية"""
    buttons = []
    for year in [1, 2, 3, 4]:
        status = "✅" if year in available_years else "❌"
        button_text = f"السنة {year} {status}"
        buttons.append([InlineKeyboardButton(button_text, callback_data=f"year_{course_id}_{year}")])

    buttons.append([InlineKeyboardButton("🔙 رجوع للمواد", callback_data="back_to_courses")])

    return InlineKeyboardMarkup(buttons)


def get_material_types_keyboard(course_id: int, year: int, types_count: dict) -> InlineKeyboardMarkup:
    """لوحة أزرار أنواع المواد"""
    from config import MATERIAL_TYPES

    buttons = []
    for type_key, type_info in MATERIAL_TYPES.items():
        count = types_count.get(type_key, 0)
        button_text = f"{type_info['icon']} {type_info['name']} ({count})"
        buttons.append([InlineKeyboardButton(button_text, callback_data=f"materials_{course_id}_{year}_{type_key}")])

    buttons.append([InlineKeyboardButton("🔙 رجوع للسنوات", callback_data=f"back_to_years_{course_id}")])

    return InlineKeyboardMarkup(buttons)


def get_materials_keyboard(materials: list, course_id: int, year: int) -> InlineKeyboardMarkup:
    """لوحة أزرار الملفات"""
    buttons = []
    for material_id, title, _, _, _ in materials:
        buttons.append([InlineKeyboardButton(f"📥 {title[:40]}", callback_data=f"download_{material_id}")])

    material_type = materials[0][3] if materials else "unknown"
    buttons.append([InlineKeyboardButton("🔙 رجوع للأنواع", callback_data=f"back_to_types_{course_id}_{year}")])

    return InlineKeyboardMarkup(buttons)


def get_download_keyboard(material_id: int) -> InlineKeyboardMarkup:
    """لوحة أزرار بعد تحميل الملف"""
    buttons = [
        [
            InlineKeyboardButton("⭐ تقييم الملف", callback_data=f"rate_{material_id}"),
            InlineKeyboardButton("🔙 رجوع", callback_data=f"back_to_materials_{material_id}"),
        ]
    ]
    return InlineKeyboardMarkup(buttons)


def get_admin_panel_keyboard() -> InlineKeyboardMarkup:
    """لوحة تحكم المشرفين"""
    buttons = [
        [InlineKeyboardButton("📤 رفع ملف جديد", callback_data="admin_upload")],
        [InlineKeyboardButton("📁 إدارة الملفات", callback_data="admin_manage")],
        [InlineKeyboardButton("📊 إحصائيات مفصلة", callback_data="admin_stats")],
        [InlineKeyboardButton("➕ إضافة مادة جديدة", callback_data="admin_add_course")],
        [InlineKeyboardButton("🔙 القائمة الرئيسية", callback_data="admin_back_main")],
    ]
    return InlineKeyboardMarkup(buttons)


def get_courses_upload_keyboard(courses: list) -> InlineKeyboardMarkup:
    """لوحة اختيار مادة للرفع"""
    buttons = []
    for course_id, course_name in courses:
        buttons.append([InlineKeyboardButton(course_name, callback_data=f"upload_course_{course_id}")])

    buttons.append([InlineKeyboardButton("🔙 رجوع", callback_data="admin_back")])

    return InlineKeyboardMarkup(buttons)


def get_years_upload_keyboard(course_id: int) -> InlineKeyboardMarkup:
    """لوحة اختيار السنة للرفع"""
    from config import ACADEMIC_YEARS

    buttons = []
    for year in ACADEMIC_YEARS:
        buttons.append([InlineKeyboardButton(f"السنة {year}", callback_data=f"upload_year_{year}")])

    buttons.append([InlineKeyboardButton("🔙 رجوع", callback_data="admin_upload")])

    return InlineKeyboardMarkup(buttons)


def get_material_types_upload_keyboard(course_id: int) -> InlineKeyboardMarkup:
    """لوحة اختيار نوع المادة للرفع"""
    from config import MATERIAL_TYPES

    buttons = []
    for type_key, type_info in MATERIAL_TYPES.items():
        buttons.append([InlineKeyboardButton(type_info["name"], callback_data=f"upload_type_{type_key}")])

    buttons.append([InlineKeyboardButton("🔙 رجوع", callback_data=f"upload_course_{course_id}")])

    return InlineKeyboardMarkup(buttons)


def get_search_results_keyboard(results: list) -> InlineKeyboardMarkup:
    """لوحة نتائج البحث"""
    buttons = []
    for material_id, title, _, _, _, _, _ in results:
        buttons.append([InlineKeyboardButton(f"📥 {title[:40]}", callback_data=f"download_{material_id}")])

    buttons.append([InlineKeyboardButton("🔍 بحث جديد", callback_data="new_search")])

    return InlineKeyboardMarkup(buttons)
