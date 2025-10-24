import logging
import sqlite3
import os
from datetime import datetime
from telegram import (
    Update, 
    ReplyKeyboardMarkup, 
    InlineKeyboardMarkup, 
    InlineKeyboardButton,
    ReplyKeyboardRemove
)
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    CallbackQueryHandler,
    ContextTypes,
    filters
)

# 🔧 إعدادات التسجيل
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# 🔑 التوكن - ضع توكن البوت هنا
TOKEN = "ضع_التوكن_الخاص_بك_هنا"

# 👥 المشرفين - ضع معرفات المشرفين هنا
ADMINS = [123456789]  # استبدل برقم ID الخاص بك

# 📊 تهيئة قاعدة البيانات
def init_database():
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    
    # جدول المواد الدراسية
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS courses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            code TEXT UNIQUE,
            description TEXT
        )
    ''')
    
    # جدول الملفات
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS materials (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            course_id INTEGER,
            year INTEGER,
            material_type TEXT,
            title TEXT NOT NULL,
            file_id TEXT,
            file_type TEXT,
            description TEXT,
            upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            uploader_id INTEGER,
            FOREIGN KEY (course_id) REFERENCES courses (id)
        )
    ''')
    
    # جدول التقييمات
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS ratings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            material_id INTEGER,
            user_id INTEGER,
            rating INTEGER CHECK(rating >= 1 AND rating <= 5),
            comment TEXT,
            rating_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (material_id) REFERENCES materials (id)
        )
    ''')
    
    # جدول التحميلات
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS downloads (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            material_id INTEGER,
            user_id INTEGER,
            download_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (material_id) REFERENCES materials (id)
        )
    ''')
    
    # إضافة المواد الأساسية
    default_courses = [
        ('برمجة الحاسوب', 'CS101', 'أساسيات البرمجة والخوارزميات'),
        ('قواعد البيانات', 'CS102', 'تصميم وإدارة قواعد البيانات'),
        ('شبكات الحاسوب', 'CS201', 'أساسيات الشبكات والاتصالات'),
        ('أمن المعلومات', 'CS301', 'الحماية والأمن السيبراني'),
        ('الذكاء الاصطناعي', 'CS401', 'الذكاء الاصطناعي وتعلم الآلة'),
        ('هياكل البيانات', 'CS202', 'التركيبات البيانات والخوارزميات'),
        ('تطوير الويب', 'CS302', 'برمجة مواقع وتطبيقات الويب'),
        ('أنظمة التشغيل', 'CS203', 'مبادئ أنظمة التشغيل')
    ]
    
    cursor.executemany(
        'INSERT OR IGNORE INTO courses (name, code, description) VALUES (?, ?, ?)',
        default_courses
    )
    
    conn.commit()
    conn.close()
    print("✅ قاعدة البيانات مهيأة بنجاح")

# 🎯 تهيئة قاعدة البيانات عند التشغيل
init_database()

# 🎹 لوحات المفاتيح
def get_main_keyboard():
    return ReplyKeyboardMarkup([
        ['📚 المواد الدراسية', '🔍 بحث متقدم'],
        ['🏫 الفصول الدراسية', '⭐ التقييمات'],
        ['📊 الإحصائيات', '👤 المساعدة']
    ], resize_keyboard=True)

def get_admin_keyboard():
    return ReplyKeyboardMarkup([
        ['🛠️ لوحة التحكم', '📤 رفع ملف'],
        ['📊 إحصائيات', '👥 إدارة المشرفين'],
        ['🔙 القائمة الرئيسية']
    ], resize_keyboard=True)

# 🏠 الأمر الرئيسي
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    welcome_text = f"""
🎓 **مرحباً بك {user.first_name} في بوت جامعة تكنولوجيا المعلومات!**

🤖 **ماذا يمكنني أن أفعل لك:**

• 📚 **تصفح جميع المواد الدراسية**
• 🔍 **الببحث في المحاضرات والملازم**
• 📖 **تحميل الملفات الدراسية**
• ⭐ **تقييم المواد والمحاضرات**
• 🏫 **تنظيم المحتوى حسب الفصول**

**اختر من الخيارات أدناه للبدء 👇**
    """
    
    if user.id in ADMINS:
        await update.message.reply_text(
            welcome_text,
            reply_markup=get_admin_keyboard(),
            parse_mode='Markdown'
        )
    else:
        await update.message.reply_text(
            welcome_text,
            reply_markup=get_main_keyboard(),
            parse_mode='Markdown'
        )

# 📚 عرض المواد الدراسية
async def show_courses(update: Update, context: ContextTypes.DEFAULT_TYPE):
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    cursor.execute("SELECT id, name, code, description FROM courses ORDER BY name")
    courses = cursor.fetchall()
    conn.close()
    
    if not courses:
        await update.message.reply_text("❌ لا توجد مواد دراسية متاحة حالياً.")
        return
    
    keyboard = []
    for course_id, name, code, description in courses:
        button_text = f"{name} ({code})"
        keyboard.append([InlineKeyboardButton(button_text, callback_data=f"course_{course_id}")])
    
    # إضافة أزرار السنوات للبحث السريع
    keyboard.extend([
        [InlineKeyboardButton("🔍 بحث في جميع المواد", callback_data="search_all")],
        [InlineKeyboardButton("📊 المواد الأكثر نشاطاً", callback_data="popular_courses")]
    ])
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text(
        "📚 **المواد الدراسية المتاحة:**\n\n"
        "اختر المادة التي تريد استعراض محتواها:",
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )

# 🏫 عرض الفصول الدراسية لمادة محددة
async def show_course_years(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    course_id = query.data.split('_')[1]
    
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM courses WHERE id = ?", (course_id,))
    course_name = cursor.fetchone()[0]
    
    # الحصول على السنوات المتاحة لهذه المادة
    cursor.execute('''
        SELECT DISTINCT year FROM materials 
        WHERE course_id = ? ORDER BY year
    ''', (course_id,))
    years = [row[0] for row in cursor.fetchall()]
    conn.close()
    
    keyboard = []
    for year in [1, 2, 3, 4]:  # جميع السنوات المحتملة
        if year in years:
            button_text = f"السنة {year} ✅"
        else:
            button_text = f"السنة {year} ❌"
        keyboard.append([InlineKeyboardButton(button_text, callback_data=f"year_{course_id}_{year}")])
    
    keyboard.append([InlineKeyboardButton("🔙 رجوع للمواد", callback_data="back_to_courses")])
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    await query.edit_message_text(
        f"🏫 **{course_name}**\n\n"
        "اختر السنة الدراسية:\n"
        "✅ = يوجد محتوى\n❌ = لا يوجد محتوى بعد",
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )

# 📁 عرض أنواع المواد لسنة محددة
async def show_material_types(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    _, course_id, year = query.data.split('_')
    
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM courses WHERE id = ?", (course_id,))
    course_name = cursor.fetchone()[0]
    
    # عد المواد لكل نوع
    cursor.execute('''
        SELECT material_type, COUNT(*) 
        FROM materials 
        WHERE course_id = ? AND year = ?
        GROUP BY material_type
    ''', (course_id, year))
    type_counts = dict(cursor.fetchall())
    conn.close()
    
    material_types = {
        'lecture': {'name': '📖 المحاضرات', 'icon': '📖'},
        'lab': {'name': '🔬 الملازم', 'icon': '🔬'},
        'explanation': {'name': '💡 الشروحات', 'icon': '💡'},
        'summary': {'name': '📝 الملخصات', 'icon': '📝'},
        'exam': {'name': '📝 الامتحانات', 'icon': '📝'}
    }
    
    keyboard = []
    for type_key, type_info in material_types.items():
        count = type_counts.get(type_key, 0)
        button_text = f"{type_info['icon']} {type_info['name']} ({count})"
        keyboard.append([InlineKeyboardButton(button_text, callback_data=f"materials_{course_id}_{year}_{type_key}")])
    
    keyboard.append([InlineKeyboardButton("🔙 رجوع للسنوات", callback_data=f"back_to_years_{course_id}")])
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    await query.edit_message_text(
        f"📁 **{course_name} - السنة {year}**\n\n"
        "اختر نوع المادة التي تريد تصفحها:",
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )

# 📄 عرض الملفات لنوع معين
async def show_materials_list(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    _, course_id, year, material_type = query.data.split('_')
    
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM courses WHERE id = ?", (course_id,))
    course_name = cursor.fetchone()[0]
    
    cursor.execute('''
        SELECT id, title, description, file_type, upload_date
        FROM materials 
        WHERE course_id = ? AND year = ? AND material_type = ?
        ORDER BY upload_date DESC
    ''', (course_id, year, material_type))
    materials = cursor.fetchall()
    conn.close()
    
    if not materials:
        await query.edit_message_text(
            f"❌ لا توجد مواد من نوع {material_type} متاحة لـ {course_name} - السنة {year}.\n\n"
            "يمكنك العودة واختيار نوع آخر.",
            reply_markup=InlineKeyboardMarkup([[
                InlineKeyboardButton("🔙 رجوع", callback_data=f"back_to_types_{course_id}_{year}")
            ]])
        )
        return
    
    material_names = {
        'lecture': 'المحاضرات',
        'lab': 'الملازم',
        'explanation': 'الشروحات',
        'summary': 'الملخصات',
        'exam': 'الامتحانات'
    }
    
    materials_text = f"📂 **{course_name} - السنة {year}**\n"
    materials_text += f"📁 **{material_names[material_type]}**\n\n"
    
    keyboard = []
    for material_id, title, description, file_type, upload_date in materials:
        materials_text += f"• {title}\n"
        if description:
            materials_text += f"  📝 {description}\n"
        materials_text += f"  📅 {upload_date[:10]}\n\n"
        
        keyboard.append([InlineKeyboardButton(f"📥 تحميل: {title}", callback_data=f"download_{material_id}")])
    
    keyboard.append([InlineKeyboardButton("🔙 رجوع للأنواع", callback_data=f"back_to_types_{course_id}_{year}")])
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    await query.edit_message_text(materials_text, reply_markup=reply_markup)

# 📥 تحميل الملف
async def download_material(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    material_id = query.data.split('_')[1]
    
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    cursor.execute('''
        SELECT m.file_id, m.file_type, m.title, c.name, m.year, m.material_type
        FROM materials m
        JOIN courses c ON m.course_id = c.id
        WHERE m.id = ?
    ''', (material_id,))
    material = cursor.fetchone()
    
    if not material:
        await query.edit_message_text("❌ الملف غير موجود.")
        return
    
    file_id, file_type, title, course_name, year, material_type = material
    
    # تسجيل التحميل
    cursor.execute(
        'INSERT INTO downloads (material_id, user_id) VALUES (?, ?)',
        (material_id, query.from_user.id)
    )
    conn.commit()
    conn.close()
    
    # إرسال الملف
    try:
        if file_type == 'document':
            await context.bot.send_document(
                chat_id=query.message.chat_id,
                document=file_id,
                caption=f"📥 **{title}**\n\n"
                       f"📚 المادة: {course_name}\n"
                       f"🏫 السنة: {year}\n"
                       f"📁 النوع: {material_type}\n\n"
                       f"✅ تم التحميل بنجاح!"
            )
        elif file_type == 'photo':
            await context.bot.send_photo(
                chat_id=query.message.chat_id,
                photo=file_id,
                caption=f"📥 **{title}**\n\n"
                       f"📚 المادة: {course_name}\n"
                       f"🏫 السنة: {year}\n"
                       f"📁 النوع: {material_type}\n\n"
                       f"✅ تم التحميل بنجاح!"
            )
        
        # عرض خيار التقييم
        keyboard = [[
            InlineKeyboardButton("⭐ تقييم الملف", callback_data=f"rate_{material_id}"),
            InlineKeyboardButton("🔙 رجوع", callback_data=f"back_to_materials_{material_id}")
        ]]
        reply_markup = InlineKeyboardMarkup(keyboard)
        
        await query.message.reply_text(
            "💬 هل تريد تقييم هذا الملف؟",
            reply_markup=reply_markup
        )
        
    except Exception as e:
        await query.message.reply_text("❌ حدث خطأ في إرسال الملف.")

# 🔍 البحث المتقدم
async def advanced_search(update: Update, context: ContextTypes.DEFAULT_TYPE):
    search_text = """
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
    
    await update.message.reply_text(
        search_text,
        reply_markup=ReplyKeyboardRemove(),
        parse_mode='Markdown'
    )

# 🔎 معالجة البحث
async def handle_search(update: Update, context: ContextTypes.DEFAULT_TYPE):
    search_query = update.message.text.strip()
    
    if not search_query:
        await update.message.reply_text(
            "❌ يرجى إدخال كلمة البحث.",
            reply_markup=get_main_keyboard()
        )
        return
    
    # تحليل عوامل التصفية
    filters = {
        'keyword': '',
        'year': None,
        'material_type': None
    }
    
    # تحويل الأنواع من العربية لإنجليزية
    type_mapping = {
        'محاضرة': 'lecture',
        'ملزمة': 'lab',
        'شرح': 'explanation',
        'ملخص': 'summary',
        'امتحان': 'exam'
    }
    
    parts = search_query.split()
    for part in parts:
        if part.startswith('سنة:'):
            try:
                filters['year'] = int(part.split(':')[1])
            except:
                pass
        elif part.startswith('نوع:'):
            arabic_type = part.split(':')[1]
            filters['material_type'] = type_mapping.get(arabic_type, arabic_type)
        else:
            filters['keyword'] += part + ' '
    
    filters['keyword'] = filters['keyword'].strip()
    
    # بناء استعلام البحث
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    
    query = '''
        SELECT m.id, m.title, m.description, c.name, m.year, m.material_type, m.upload_date
        FROM materials m
        JOIN courses c ON m.course_id = c.id
        WHERE (m.title LIKE ? OR m.description LIKE ? OR c.name LIKE ?)
    '''
    params = [f"%{filters['keyword']}%", f"%{filters['keyword']}%", f"%{filters['keyword']}%"]
    
    if filters['year']:
        query += " AND m.year = ?"
        params.append(filters['year'])
    
    if filters['material_type']:
        query += " AND m.material_type = ?"
        params.append(filters['material_type'])
    
    query += " ORDER BY m.upload_date DESC LIMIT 20"
    
    cursor.execute(query, params)
    results = cursor.fetchall()
    conn.close()
    
    if not results:
        await update.message.reply_text(
            "❌ لم يتم العثور على نتائج تطابق بحثك.",
            reply_markup=get_main_keyboard()
        )
        return
    
    # عرض النتائج
    response = "🔍 **نتائج البحث:**\n\n"
    
    keyboard = []
    for material_id, title, description, course_name, year, material_type, upload_date in results:
        response += f"📁 **{title}**\n"
        response += f"📚 {course_name} - السنة {year}\n"
        response += f"📅 {upload_date[:10]}\n"
        if description:
            response += f"📝 {description}\n"
        response += "───────────────\n"
        
        keyboard.append([InlineKeyboardButton(
            f"📥 {title[:30]}...", 
            callback_data=f"download_{material_id}"
        )])
    
    keyboard.append([InlineKeyboardButton("🔍 بحث جديد", callback_data="new_search")])
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text(
        response,
        reply_markup=reply_markup,
        parse_mode='Markdown'
    )

# 🛠️ لوحة تحكم المشرفين
async def admin_panel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id not in ADMINS:
        await update.message.reply_text("❌ ليس لديك صلاحية الدخول هنا.")
        return
    
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    
    # إحصائيات سريعة
    cursor.execute("SELECT COUNT(*) FROM materials")
    total_materials = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM courses")
    total_courses = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM downloads")
    total_downloads = cursor.fetchone()[0]
    
    conn.close()
    
    admin_text = f"""
🛠️ **لوحة تحكم المشرفين**

📊 **إحصائيات سريعة:**
• 📁 إجمالي الملفات: {total_materials}
• 📚 عدد المواد: {total_courses}
• 📥 إجمالي التحميلات: {total_downloads}

**اختر من الخيارات:**
    """
    
    keyboard = [
        [InlineKeyboardButton("📤 رفع ملف جديد", callback_data="admin_upload")],
        [InlineKeyboardButton("📁 إدارة الملفات", callback_data="admin_manage")],
        [InlineKeyboardButton("📊 إحصائيات مفصلة", callback_data="admin_stats")],
        [InlineKeyboardButton("➕ إضافة مادة جديدة", callback_data="admin_add_course")],
        [InlineKeyboardButton("🔙 القائمة الرئيسية", callback_data="admin_back_main")]
    ]
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    await update.message.reply_text(admin_text, reply_markup=reply_markup)

# 📤 بدء رفع ملف جديد
async def start_upload(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    if query.from_user.id not in ADMINS:
        await query.edit_message_text("❌ ليس لديك صلاحية الدخول هنا.")
        return
    
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    cursor.execute("SELECT id, name FROM courses ORDER BY name")
    courses = cursor.fetchall()
    conn.close()
    
    keyboard = []
    for course_id, course_name in courses:
        keyboard.append([InlineKeyboardButton(course_name, callback_data=f"upload_course_{course_id}")])
    
    keyboard.append([InlineKeyboardButton("🔙 رجوع", callback_data="admin_back")])
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    await query.edit_message_text(
        "📤 **رفع ملف جديد**\n\n"
        "اختر المادة:",
        reply_markup=reply_markup
    )

# 🏫 اختيار السنة للرفع
async def choose_upload_year(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    course_id = query.data.split('_')[2]
    context.user_data['upload_course_id'] = course_id
    
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM courses WHERE id = ?", (course_id,))
    course_name = cursor.fetchone()[0]
    conn.close()
    
    context.user_data['upload_course_name'] = course_name
    
    keyboard = [
        [InlineKeyboardButton("السنة الأولى", callback_data="upload_year_1")],
        [InlineKeyboardButton("السنة الثانية", callback_data="upload_year_2")],
        [InlineKeyboardButton("السنة الثالثة", callback_data="upload_year_3")],
        [InlineKeyboardButton("السنة الرابعة", callback_data="upload_year_4")],
        [InlineKeyboardButton("🔙 رجوع", callback_data="admin_upload")]
    ]
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    await query.edit_message_text(
        f"🏫 **{course_name}**\n\n"
        "اختر السنة الدراسية:",
        reply_markup=reply_markup
    )

# 📁 اختيار نوع المادة للرفع
async def choose_upload_type(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    year = query.data.split('_')[2]
    context.user_data['upload_year'] = year
    
    material_types = [
        ("📖 محاضرة", "lecture"),
        ("🔬 ملزمة", "lab"),
        ("💡 شرح", "explanation"),
        ("📝 ملخص", "summary"),
        ("📝 امتحان", "exam")
    ]
    
    keyboard = []
    for display_name, type_key in material_types:
        keyboard.append([InlineKeyboardButton(display_name, callback_data=f"upload_type_{type_key}")])
    
    keyboard.append([InlineKeyboardButton("🔙 رجوع", callback_data=f"upload_course_{context.user_data['upload_course_id']}")])
    
    reply_markup = InlineKeyboardMarkup(keyboard)
    await query.edit_message_text(
        "📁 اختر نوع المادة:",
        reply_markup=reply_markup
    )

# 📝 إدخال عنوان الملف
async def enter_file_title(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    material_type = query.data.split('_')[2]
    context.user_data['upload_type'] = material_type
    
    type_names = {
        'lecture': 'محاضرة',
        'lab': 'ملزمة',
        'explanation': 'شرح',
        'summary': 'ملخص',
        'exam': 'امتحان'
    }
    
    await query.edit_message_text(
        f"📤 **تفاصيل الرفع:**\n\n"
        f"📚 المادة: {context.user_data['upload_course_name']}\n"
        f"🏫 السنة: {context.user_data['upload_year']}\n"
        f"📁 النوع: {type_names[material_type]}\n\n"
        "✏️ **الآن أرسل عنوان الملف:**\n"
        "(مثال: 'محاضرة 1 - المدخل إلى البرمجة')"
    )
    
    context.user_data['upload_step'] = 'waiting_title'

# 💾 معالجة رفع الملف
async def handle_file_upload(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.user_data.get('upload_step') == 'waiting_file':
        return
    
    user_id = update.effective_user.id
    if user_id not in ADMINS:
        return
    
    file = None
    file_type = None
    
    if update.message.document:
        file = update.message.document
        file_type = 'document'
    elif update.message.photo:
        file = update.message.photo[-1]
        file_type = 'photo'
    else:
        await update.message.reply_text("❌ يرجى إرسال ملف أو صورة.")
        return
    
    # حفظ في قاعدة البيانات
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    
    cursor.execute('''
        INSERT INTO materials (course_id, year, material_type, title, file_id, file_type, description, uploader_id)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        context.user_data['upload_course_id'],
        context.user_data['upload_year'],
        context.user_data['upload_type'],
        context.user_data['upload_title'],
        file.file_id,
        file_type,
        context.user_data.get('upload_description', ''),
        user_id
    ))
    
    conn.commit()
    conn.close()
    
    # تنظيف البيانات المؤقتة
    for key in ['upload_step', 'upload_course_id', 'upload_course_name', 'upload_year', 'upload_type', 'upload_title']:
        context.user_data.pop(key, None)
    
    await update.message.reply_text(
        "✅ **تم رفع الملف بنجاح!**\n\n"
        "يمكنك متابعة رفع الملفات أو العودة للقائمة الرئيسية.",
        reply_markup=get_admin_keyboard()
    )

# 📝 معالجة عنوان الملف
async def handle_file_title(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.user_data.get('upload_step') == 'waiting_title':
        return
    
    title = update.message.text.strip()
    if not title:
        await update.message.reply_text("❌ يرجى إرسال عنوان صحيح.")
        return
    
    context.user_data['upload_title'] = title
    context.user_data['upload_step'] = 'waiting_description'
    
    await update.message.reply_text(
        "📝 **أرسل وصفاً للملف (اختياري):**\n"
        "(اضغط /skip لتخطي هذه الخطوة)"
    )

# 🔄 معالجة وصف الملف
async def handle_file_description(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.user_data.get('upload_step') == 'waiting_description':
        return
    
    description = update.message.text.strip()
    context.user_data['upload_description'] = description
    context.user_data['upload_step'] = 'waiting_file'
    
    type_names = {
        'lecture': 'محاضرة',
        'lab': 'ملزمة',
        'explanation': 'شرح',
        'summary': 'ملخص',
        'exam': 'امتحان'
    }
    
    await update.message.reply_text(
        f"📤 **تفاصيل الرفع:**\n\n"
        f"📚 المادة: {context.user_data['upload_course_name']}\n"
        f"🏫 السنة: {context.user_data['upload_year']}\n"
        f"📁 النوع: {type_names[context.user_data['upload_type']]}\n"
        f"📄 العنوان: {context.user_data['upload_title']}\n"
        f"📝 الوصف: {description if description else 'لا يوجد'}\n\n"
        "📎 **الآن أرسل الملف:**\n"
        "(يمكنك إرسال ملف PDF، صورة، أو مستند)"
    )

# ⏭️ تخطي الوصف
async def skip_description(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.user_data.get('upload_step') == 'waiting_description':
        return
    
    context.user_data['upload_description'] = ''
    context.user_data['upload_step'] = 'waiting_file'
    
    type_names = {
        'lecture': 'محاضرة',
        'lab': 'ملزمة',
        'explanation': 'شرح',
        'summary': 'ملخص',
        'exam': 'امتحان'
    }
    
    await update.message.reply_text(
        f"📤 **تفاصيل الرفع:**\n\n"
        f"📚 المادة: {context.user_data['upload_course_name']}\n"
        f"🏫 السنة: {context.user_data['upload_year']}\n"
        f"📁 النوع: {type_names[context.user_data['upload_type']]}\n"
        f"📄 العنوان: {context.user_data['upload_title']}\n"
        f"📝 الوصف: لا يوجد\n\n"
        "📎 **الآن أرسل الملف:**\n"
        "(يمكنك إرسال ملف PDF، صورة، أو مستند)"
    )

# 📊 الإحصائيات
async def show_stats(update: Update, context: ContextTypes.DEFAULT_TYPE):
    conn = sqlite3.connect('university_bot.db')
    cursor = conn.cursor()
    
    # إحصائيات عامة
    cursor.execute("SELECT COUNT(*) FROM materials")
    total_materials = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM courses")
    total_courses = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM downloads")
    total_downloads = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM ratings")
    total_ratings = cursor.fetchone()[0]
    
    # المواد الأكثر تحميلاً
    cursor.execute('''
        SELECT c.name, COUNT(d.id) as download_count
        FROM materials m
        JOIN courses c ON m.course_id = c.id
        JOIN downloads d ON m.id = d.material_id
        GROUP BY c.name
        ORDER BY download_count DESC
        LIMIT 5
    ''')
    popular_courses = cursor.fetchall()
    
    # أحدث الملفات
    cursor.execute('''
        SELECT m.title, c.name, m.upload_date
        FROM materials m
        JOIN courses c ON m.course_id = c.id
        ORDER BY m.upload_date DESC
        LIMIT 5
    ''')
    recent_files = cursor.fetchall()
    
    conn.close()
    
    stats_text = f"""
📊 **إحصائيات البوت**

📈 **إحصائيات عامة:**
• 📁 إجمالي الملفات: {total_materials}
• 📚 عدد المواد: {total_courses}
• 📥 إجمالي التحميلات: {total_downloads}
• ⭐ إجمالي التقييمات: {total_ratings}

🏆 **المواد الأكثر نشاطاً:**
"""
    
    for course_name, downloads in popular_courses:
        stats_text += f"• {course_name}: {downloads} تحميل\n"
    
    stats_text += "\n🆕 **أحدث الملفات:**\n"
    for title, course_name, upload_date in recent_files:
        stats_text += f"• {title} ({course_name}) - {upload_date[:10]}\n"
    
    await update.message.reply_text(stats_text, reply_markup=get_main_keyboard())

# 🔄 معالجة أزرار الرجوع
async def handle_back_buttons(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()
    
    back_action = query.data
    
    if back_action == "back_to_courses":
        await show_courses_from_query(query)
    elif back_action.startswith("back_to_years"):
        course_id = back_action.split("_")[3]
        await show_course_years_from_query(query, course_id)
    elif back_action.startswith("back_to_types"):
        _, course_id, year = back_action.split("_")[2:]
        await show_material_types_from_query(query, course_id, year)
    elif back_action == "admin_back":
        await admin_panel_from_query(query)
    elif back_action == "admin_back_main":
        await start_from_query(query)
    elif back_action == "new_search":
        await advanced_search_from_query(query)

# 🔄 دوال مساعدة للرجوع
async def show_courses_from_query(query):
    await show_courses(None, type('obj', (object,), {'message': type('obj', (object,), {'reply_text': query.edit_message_text})()}))

async def show_course_years_from_query(query, course_id):
    callback_data = type('obj', (object,), {'data': f'course_{course_id}', 'edit_message_text': query.edit_message_text})()
    await show_course_years(type('obj', (object,), {'callback_query': callback_data})(), None)

async def show_material_types_from_query(query, course_id, year):
    callback_data = type('obj', (object,), {'data': f'year_{course_id}_{year}', 'edit_message_text': query.edit_message_text})()
    await show_material_types(type('obj', (object,), {'callback_query': callback_data})(), None)

async def admin_panel_from_query(query):
    await admin_panel(type('obj', (object,), {'message': type('obj', (object,), {'reply_text': query.edit_message_text})()})(), None)

async def start_from_query(query):
    await start(type('obj', (object,), {'message': type('obj', (object,), {'reply_text': query.edit_message_text})()})(), None)

async def advanced_search_from_query(query):
    await advanced_search(type('obj', (object,), {'message': type('obj', (object,), {'reply_text': query.edit_message_text})()})(), None)

# 🎯 معالجة الرسائل الرئيسية
async def handle_main_messages(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text
    user_id = update.effective_user.id
    
    if text == '📚 المواد الدراسية':
        await show_courses(update, context)
    elif text == '🔍 بحث متقدم':
        await advanced_search(update, context)
    elif text == '🏫 الفصول الدراسية':
        await update.message.reply_text(
            "🏫 **الفصول الدراسية**\n\n"
            "استخدم خيار 'المواد الدراسية' لتصفح المحتوى حسب الفصول.",
            reply_markup=get_main_keyboard()
        )
    elif text == '⭐ التقييمات':
        await update.message.reply_text(
            "⭐ **نظام التقييمات**\n\n"
            "سيتم تفعيل نظام التقييمات قريباً!",
            reply_markup=get_main_keyboard()
        )
    elif text == '📊 الإحصائيات':
        await show_stats(update, context)
    elif text == '👤 المساعدة':
        await update.message.reply_text(
            "👤 **مساعدة واستفسارات**\n\n"
            "للأسئلة والاستفسارات:\n"
            "📧 البريد: support@university.edu\n"
            "📞 الهاتف: 0123456789\n\n"
            "لتطوير البوت أو الإبلاغ عن مشاكل:\n"
            "@username",
            reply_markup=get_main_keyboard()
        )
    elif text == '🛠️ لوحة التحكم' and user_id in ADMINS:
        await admin_panel(update, context)
    elif text == '📤 رفع ملف' and user_id in ADMINS:
        await start_upload(update, context)
    elif text == '📊 إحصائيات' and user_id in ADMINS:
        await show_stats(update, context)
    elif text == '🔙 القائمة الرئيسية':
        await start(update, context)
    else:
        await update.message.reply_text(
            "❌ لم أفهم طلبك.\n"
            "استخدم الأزرار أو أرسل /start للبدء.",
            reply_markup=get_main_keyboard() if user_id not in ADMINS else get_admin_keyboard()
        )

# 🚀 التشغيل الرئيسي
def main():
    try:
        # إنشاء التطبيق
        application = Application.builder().token(TOKEN).build()
        
        # Handlers الأساسية
        application.add_handler(CommandHandler("start", start))
        application.add_handler(CommandHandler("admin", admin_panel))
        application.add_handler(CommandHandler("search", advanced_search))
        application.add_handler(CommandHandler("stats", show_stats))
        application.add_handler(CommandHandler("skip", skip_description))
        
        # Callback Query Handlers
        application.add_handler(CallbackQueryHandler(show_course_years, pattern="^course_"))
        application.add_handler(CallbackQueryHandler(show_material_types, pattern="^year_"))
        application.add_handler(CallbackQueryHandler(show_materials_list, pattern="^materials_"))
        application.add_handler(CallbackQueryHandler(download_material, pattern="^download_"))
        application.add_handler(CallbackQueryHandler(handle_back_buttons, pattern="^back_to_"))
        application.add_handler(CallbackQueryHandler(start_upload, pattern="^admin_upload$"))
        application.add_handler(CallbackQueryHandler(choose_upload_year, pattern="^upload_course_"))
        application.add_handler(CallbackQueryHandler(choose_upload_type, pattern="^upload_year_"))
        application.add_handler(CallbackQueryHandler(enter_file_title, pattern="^upload_type_"))
        application.add_handler(CallbackQueryHandler(handle_back_buttons, pattern="^admin_back"))
        application.add_handler(CallbackQueryHandler(handle_back_buttons, pattern="^admin_back_main"))
        application.add_handler(CallbackQueryHandler(handle_back_buttons, pattern="^new_search"))
        
        # معالجة البحث
        application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_search))
        
        # معالجة رفع الملفات (للمشرفين)
        application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_file_title))
        application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_file_description))
        application.add_handler(MessageHandler(filters.DOCUMENT | filters.PHOTO, handle_file_upload))
        
        # معالجة الرسائل الرئيسية
        application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_main_messages))
        
        print("=" * 60)
        print("🎓 بوت جامعة تكنولوجيا المعلومات يعمل بنجاح!")
        print("📍 اذهب إلى تيليجرام وجرب البوت")
        print("👥 عدد المشرفين:", len(ADMINS))
        print("⏹️  لإيقاف البوت: Ctrl + C")
        print("=" * 60)
        
        # بدء البوت
        application.run_polling()
        
    except Exception as e:
        print(f"❌ خطأ في التشغيل: {e}")
        print("\n🔧 تأكد من:")
        print("   - التوكن صحيح ومفعّل")
        print("   - المكتبات مثبتة (python-telegram-bot)")
        print("   - الاتصال بالإنترنت فعال")
        print("   - البوت غير محظور في تيليجرam")

if __name__ == '__main__':
    main()
