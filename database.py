# 📊 إدارة قاعدة البيانات
"""
طبقة منفصلة لإدارة جميع عمليات قاعدة البيانات
يوفر دوال واضحة وآمنة للتعامل مع البيانات
"""

import sqlite3
import logging
from typing import List, Tuple, Optional, Dict
from contextlib import contextmanager
from config import DATABASE_NAME, DEFAULT_COURSES

logger = logging.getLogger(__name__)


class DatabaseManager:
    """إدارة قاعدة البيانات بشكل آمن وفعال"""

    def __init__(self, db_name: str = DATABASE_NAME):
        self.db_name = db_name
        self._init_database()

    @contextmanager
    def _get_connection(self):
        """مدير السياق للتعامل الآمن مع الاتصال"""
        conn = sqlite3.connect(self.db_name)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        finally:
            conn.close()

    def _init_database(self) -> None:
        """تهيئة قاعدة البيانات وإنشاء الجداول"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                self._create_tables(cursor)
                self._insert_default_courses(cursor)
                conn.commit()
            logger.info("✅ قاعدة البيانات مهيأة بنجاح")
        except Exception as e:
            logger.error(f"❌ خطأ في تهيئة قاعدة البيانات: {e}")
            raise

    @staticmethod
    def _create_tables(cursor) -> None:
        """إنشاء جداول قاعدة البيانات"""
        # جدول المواد الدراسية
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS courses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT UNIQUE NOT NULL,
                code TEXT UNIQUE,
                description TEXT
            )
        """
        )

        # جدول الملفات
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS materials (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                course_id INTEGER NOT NULL,
                year INTEGER NOT NULL,
                material_type TEXT NOT NULL,
                title TEXT NOT NULL,
                file_id TEXT NOT NULL,
                file_type TEXT NOT NULL,
                description TEXT,
                upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                uploader_id INTEGER NOT NULL,
                FOREIGN KEY (course_id) REFERENCES courses (id)
            )
        """
        )

        # جدول التقييمات
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS ratings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                material_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
                comment TEXT,
                rating_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (material_id) REFERENCES materials (id)
            )
        """
        )

        # جدول التحميلات
        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS downloads (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                material_id INTEGER NOT NULL,
                user_id INTEGER NOT NULL,
                download_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (material_id) REFERENCES materials (id)
            )
        """
        )

    @staticmethod
    def _insert_default_courses(cursor) -> None:
        """إدراج المواد الدراسية الافتراضية"""
        cursor.executemany(
            "INSERT OR IGNORE INTO courses (name, code, description) VALUES (?, ?, ?)",
            DEFAULT_COURSES,
        )

    # ============ عمليات المواد الدراسية ============

    def get_all_courses(self) -> List[Tuple]:
        """الحصول على جميع المواد الدراسية"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT id, name, code, description FROM courses ORDER BY name")
                return cursor.fetchall()
        except Exception as e:
            logger.error(f"❌ خطأ في جلب المواد: {e}")
            return []

    def get_course_by_id(self, course_id: int) -> Optional[Tuple]:
        """الحصول على مادة برقمها"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute("SELECT id, name, code, description FROM courses WHERE id = ?", (course_id,))
                return cursor.fetchone()
        except Exception as e:
            logger.error(f"❌ خطأ في جلب المادة {course_id}: {e}")
            return None

    # ============ عمليات الملفات ============

    def get_materials_by_course_and_year(self, course_id: int, year: int) -> List[Tuple]:
        """الحصول على الملفات حسب المادة والسنة"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT DISTINCT year FROM materials 
                    WHERE course_id = ? ORDER BY year
                """,
                    (course_id,),
                )
                return [row[0] for row in cursor.fetchall()]
        except Exception as e:
            logger.error(f"❌ خطأ في جلب السنوات: {e}")
            return []

    def get_materials_by_type(
        self, course_id: int, year: int, material_type: str
    ) -> List[Tuple]:
        """الحصول على الملفات حسب النوع"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT id, title, description, file_type, upload_date
                    FROM materials 
                    WHERE course_id = ? AND year = ? AND material_type = ?
                    ORDER BY upload_date DESC
                """,
                    (course_id, year, material_type),
                )
                return cursor.fetchall()
        except Exception as e:
            logger.error(f"❌ خطأ في جلب الملفات: {e}")
            return []

    def get_material_by_id(self, material_id: int) -> Optional[Tuple]:
        """الحصول على ملف برقمه"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT m.id, m.file_id, m.file_type, m.title, c.name, m.year, m.material_type
                    FROM materials m
                    JOIN courses c ON m.course_id = c.id
                    WHERE m.id = ?
                """,
                    (material_id,),
                )
                return cursor.fetchone()
        except Exception as e:
            logger.error(f"❌ خطأ في جلب الملف {material_id}: {e}")
            return None

    def get_material_types_count(self, course_id: int, year: int) -> Dict[str, int]:
        """عد الملفات لكل نوع"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT material_type, COUNT(*) 
                    FROM materials 
                    WHERE course_id = ? AND year = ?
                    GROUP BY material_type
                """,
                    (course_id, year),
                )
                return dict(cursor.fetchall())
        except Exception as e:
            logger.error(f"❌ خطأ في عد أنواع الملفات: {e}")
            return {}

    def insert_material(
        self,
        course_id: int,
        year: int,
        material_type: str,
        title: str,
        file_id: str,
        file_type: str,
        description: str,
        uploader_id: int,
    ) -> bool:
        """إدراج ملف جديد"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    INSERT INTO materials 
                    (course_id, year, material_type, title, file_id, file_type, description, uploader_id)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                    (course_id, year, material_type, title, file_id, file_type, description, uploader_id),
                )
                conn.commit()
                logger.info(f"✅ تم إدراج ملف جديد: {title}")
                return True
        except Exception as e:
            logger.error(f"❌ خطأ في إدراج الملف: {e}")
            return False

    # ============ عمليات التحميل ============

    def record_download(self, material_id: int, user_id: int) -> bool:
        """تسجيل تحميل جديد"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    "INSERT INTO downloads (material_id, user_id) VALUES (?, ?)",
                    (material_id, user_id),
                )
                conn.commit()
                return True
        except Exception as e:
            logger.error(f"❌ خطأ في تسجيل التحميل: {e}")
            return False

    # ============ عمليات البحث ============

    def search_materials(
        self, keyword: str, year: Optional[int] = None, material_type: Optional[str] = None, limit: int = 20
    ) -> List[Tuple]:
        """البحث عن الملفات"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                query = """
                    SELECT m.id, m.title, m.description, c.name, m.year, m.material_type, m.upload_date
                    FROM materials m
                    JOIN courses c ON m.course_id = c.id
                    WHERE (m.title LIKE ? OR m.description LIKE ? OR c.name LIKE ?)
                """
                params = [f"%{keyword}%", f"%{keyword}%", f"%{keyword}%"]

                if year:
                    query += " AND m.year = ?"
                    params.append(year)

                if material_type:
                    query += " AND m.material_type = ?"
                    params.append(material_type)

                query += f" ORDER BY m.upload_date DESC LIMIT {limit}"

                cursor.execute(query, params)
                return cursor.fetchall()
        except Exception as e:
            logger.error(f"❌ خطأ في البحث: {e}")
            return []

    # ============ عمليات الإحصائيات ============

    def get_statistics(self) -> Dict[str, int]:
        """الحصول على الإحصائيات العامة"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()

                cursor.execute("SELECT COUNT(*) FROM materials")
                total_materials = cursor.fetchone()[0]

                cursor.execute("SELECT COUNT(*) FROM courses")
                total_courses = cursor.fetchone()[0]

                cursor.execute("SELECT COUNT(*) FROM downloads")
                total_downloads = cursor.fetchone()[0]

                cursor.execute("SELECT COUNT(*) FROM ratings")
                total_ratings = cursor.fetchone()[0]

                return {
                    "materials": total_materials,
                    "courses": total_courses,
                    "downloads": total_downloads,
                    "ratings": total_ratings,
                }
        except Exception as e:
            logger.error(f"❌ خطأ في جلب الإحصائيات: {e}")
            return {}

    def get_popular_courses(self, limit: int = 5) -> List[Tuple]:
        """الحصول على المواد الأكثر تحميلاً"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT c.name, COUNT(d.id) as download_count
                    FROM materials m
                    JOIN courses c ON m.course_id = c.id
                    JOIN downloads d ON m.id = d.material_id
                    GROUP BY c.name
                    ORDER BY download_count DESC
                    LIMIT ?
                """,
                    (limit,),
                )
                return cursor.fetchall()
        except Exception as e:
            logger.error(f"❌ خطأ في جلب المواد الشهيرة: {e}")
            return []

    def get_recent_files(self, limit: int = 5) -> List[Tuple]:
        """الحصول على أحدث الملفات"""
        try:
            with self._get_connection() as conn:
                cursor = conn.cursor()
                cursor.execute(
                    """
                    SELECT m.title, c.name, m.upload_date
                    FROM materials m
                    JOIN courses c ON m.course_id = c.id
                    ORDER BY m.upload_date DESC
                    LIMIT ?
                """,
                    (limit,),
                )
                return cursor.fetchall()
        except Exception as e:
            logger.error(f"❌ خطأ في جلب الملفات الحديثة: {e}")
            return []


# إنشاء نسخة واحدة من مدير قاعدة البيانات
db_manager = DatabaseManager()
