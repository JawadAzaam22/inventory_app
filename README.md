## تطبيق إدارة المخزون (Inventory App)

تطبيق Flutter بسيط وعملي لإدارة مخزون محل، مع دعم كامل للغة العربية واتجاه النص من اليمين لليسار، مع واجهة عصرية وثيم فاتح/غامق، واعتماد نمط **BLoC (Cubit)** لإدارة الحالة مع فصل واضح بين طبقة البيانات وطبقة العرض.

---

### 1️⃣ الهدف من التطبيق

- إدارة المنتجات (إضافة، تعديل، حذف، تتبع الكميات).
- إدارة العروض (Offers) مع صور وأسعار بالليرة.
- تسجيل عمليات البيع وحساب الأرباح.
- إدارة سعر الصرف بين الدولار والليرة.
- إنشاء تقارير ورسوم بيانية وحفظ تقرير PDF.
- نسخ احتياطي لقاعدة البيانات والصور واستعادتها بين الأجهزة.

---

### 2️⃣ الهيكلية العامة (Architecture)

- **State Management**: استخدام `flutter_bloc` مع `InventoryCubit` و`InventoryState`.
- **Separation of Concerns**:
  - `database/db_helper.dart`: مسؤول عن التعامل المباشر مع قاعدة بيانات `sqflite` (إنشاء الجداول وفتح الاتصال).
  - `bloc/inventory_cubit.dart`: مسؤول عن منطق الأعمال (Business Logic) الخاص بالمنتجات، المبيعات، العروض، سعر الصرف، السلة، والتصنيفات.
  - `screens/*.dart`: طبقة العرض (UI) فقط، تتفاعل مع الـ Cubit عبر `BlocBuilder` / `context.read<InventoryCubit>()` بدون أي منطق قواعد بيانات.
  - `services/pdf_report_service.dart`: خدمة مستقلة لتوليد تقارير PDF من بيانات الـ Cubit.

مسار تدفق البيانات باختصار:

1. الـ UI يستدعي دوال من `InventoryCubit` (مثل `addProduct`, `addOffer`, `checkoutCart`, `addExchangeRate` ...).
2. الـ Cubit يتعامل مع `DatabaseHelper` ويحدّث الحالة `InventoryState` عبر `emit`.
3. الـ UI يُعاد بناؤه تلقائياً عبر `BlocBuilder` بناءً على الحالة الجديدة.

---

### 3️⃣ أهم الموديولات / الملفات

- `lib/main.dart`
  - يهيئ الـ `InventoryCubit` باستخدام `BlocProvider`:
    - `InventoryCubit(DatabaseHelper())..loadAll()`
  - يضبط الثيمات (فاتح/غامق) باستخدام `ThemeData` و`ColorScheme.fromSeed`.
  - يلف التطبيق بـ `GetMaterialApp` لدعم التنقل السريع والحوار/التنبيهات.

- `lib/bloc/inventory_cubit.dart`
  - يحتوي على:
    - `InventoryState` (غير قابل للتغيير Immutable) يحوي:
      - `products`, `allProducts`, `offers`, `sales`, `exchangeRates`
      - `categories` (تصنيفات المنتجات)
      - `cartItems` (سلة المشتريات)
      - `currentRate` (سعر الصرف الحالي)
      - `searchQuery`, `isLoading`, `errorMessage`
    - `InventoryCubit`:
      - `loadAll()`: تحميل كل البيانات من قاعدة البيانات.
      - `addProduct / updateProduct / deleteProduct`.
      - `addOffer / deleteOffer`.
      - `addSale(...)`: تسجيل عملية بيع مفردة لمنتج.
      - `addExchangeRate(...)`: إضافة سعر صرف جديد وتحديث السعر الحالي.
      - `calculateProfitLoss()`: حساب سيناريوهات الربح (فعلي/أفضل/أسوأ حالة).
      - `searchProducts(query)`: فلترة المنتجات حسب النص المدخل.
      - `addCategory(name)`: إضافة تصنيف جديد (للفلترة والاستخدام لاحقاً في المنتجات).
      - إدارة السلة: `addToCart`, `updateCartQuantity`, `removeFromCart`, `clearCart`, `checkoutCart`.

- `lib/database/db_helper.dart`
  - مسؤول عن:
    - إنشاء جداول: `products`, `sales`, `exchange_rates`, `offers`.
    - فتح قاعدة البيانات `inventory.db` وإرجاع كائن `Database`.
    - إغلاق قاعدة البيانات عند الحاجة (`closeDb`).

- `lib/screens/home_screen.dart`
  - الشاشة الرئيسية مع **BottomNavigationBar** بثلاث تبويبات:
    1. **المنتجات**:
       - بحث نصي عن المنتجات.
       - شريط تصنيفات (Categories) باستخدام Chips:
         - "الكل" + تصنيفات ديناميكية من قاعدة البيانات.
         - زر "إضافة تصنيف" يفتح حوار لإضافة تصنيف جديد.
       - شبكة منتجات مع صورة وسعر ومخزون وتصنيف.
       - أزرار لكل منتج:
         - تعديل (Edit).
         - إضافة إلى السلة (Add to Cart).
         - بيع مباشر (فتح `SalesScreen`).
         - حذف.
       - زر سلة (Cart) في الـ AppBar يفتح `CartScreen`.
    2. **العروض**:
       - قائمة عروض مع صورة، وصف، وسعر بالليرة، مع إمكانية حذف العرض.
    3. **الإعدادات**:
       - بطاقات للتنقل السريع إلى:
         - المظهر والثيم (حاليًا يتبع إعداد النظام).
         - التقارير (`ReportsScreen`).
         - سعر الصرف (`ExchangeRateScreen`).
         - النسخ الاحتياطي والاستعادة (`BackupRestoreScreen`).

- `lib/screens/add_product_screen.dart` / `edit_product_screen.dart`
  - نماذج لإضافة/تعديل منتج:
    - اسم المنتج، السعر بالدولار، الكمية، التصنيف، الصورة.
    - قائمة التصنيفات تعتمد على `InventoryState.categories` (مع قيم افتراضية عند عدم وجود بيانات).
    - عند الحفظ تستدعي `InventoryCubit.addProduct` أو `updateProduct`، بدون تواصل مباشر مع قاعدة البيانات.

- `lib/screens/add_offer_screen.dart`
  - نموذج لإضافة عرض مع صورة وسعر بالليرة.
  - يستخدم `InventoryCubit.addOffer` لحفظ العرض.

- `lib/screens/sales_screen.dart`
  - شاشة بيع منتج واحد:
    - تعرض سعر الصرف الحالي من `InventoryState.currentRate`.
    - تعرض سعر المنتج والمخزون المتاح.
    - إدخال الكمية المراد بيعها.
    - حساب الإجمالي بالدولار والليرة محلياً في الشاشة.
    - عند تأكيد البيع:
      - تستدعي `InventoryCubit.addSale` الذي يتحقق من توفر المخزون ويحدث قاعدة البيانات وجداول المبيعات.

- `lib/screens/cart_screen.dart`
  - شاشة سلة المشتريات:
    - تعرض كل العناصر الموجودة في `state.cartItems`.
    - إمكانية تعديل الكمية لكل منتج أو حذفه من السلة.
    - حساب الإجمالي بالدولار والليرة بناءً على `state.currentRate`.
    - زر "تأكيد البيع لكل السلة" يستدعي `InventoryCubit.checkoutCart` لتنفيذ البيع الجماعي وتحديث الكميات في قاعدة البيانات.

- `lib/screens/exchange_rate_screen.dart`
  - إدخال سعر صرف جديد بالدقيقة.
  - حفظ السعر باستخدام `InventoryCubit.addExchangeRate`.
  - عرض قائمة بكل أسعار الصرف السابقة من `state.exchangeRates` (الأحدث أولاً).

- `lib/screens/reports_screen.dart`
  - تعرض بطاقات تحليل الربح:
    - الربح الفعلي، أفضل سيناريو، الفرق المحتمل.
  - رسم بياني لتطور سعر الصرف (باستخدام `syncfusion_flutter_charts`).
  - رسم بياني للمبيعات حسب المنتج.
  - زر لتوليد تقرير PDF عبر `PdfReportService.generateReport` باستخدام بيانات الـ Cubit.

- `lib/screens/backup_restore_screen.dart`
  - تصدير قاعدة البيانات + مجلد الصور إلى ملف ZIP باستخدام:
    - `archive`, `file_saver`.
  - استيراد ملف ZIP:
    - استبدال قاعدة البيانات الحالية والملفات.
    - استدعاء `InventoryCubit.loadAll()` لتحديث واجهة التطبيق بالبيانات المستوردة.

---

### 4️⃣ المزايا (Features) المستخدمة

- **إدارة الحالة بـ BLoC/Cubit**:
  - فصل واضح بين منطق الأعمال (Cubit) وواجهة المستخدم (Widgets).
  - حالة واحدة شاملة `InventoryState` تغطي كل أجزاء المخزون والمبيعات والعروض وسعر الصرف والسلة.

- **Local Database (Sqflite)**:
  - تخزين دائم للمنتجات، المبيعات، العروض، وأسعار الصرف في `inventory.db`.

- **إدارة الصور محليًا**:
  - تخزين صور المنتجات والعروض في مجلد `app_images` داخل Documents الخاص بالتطبيق.

- **سلة مشتريات (Cart) مع بيع جماعي**:
  - إمكانية إضافة أكثر من منتج للسلة وبيعها دفعة واحدة مع تحديث المخزون وتسجيل العمليات في جدول المبيعات.

- **تصنيفات ديناميكية (Categories)**:
  - استنباط التصنيفات من قاعدة البيانات + إمكانية إضافة تصنيفات جديدة يدويًا لسهولة الفلترة.

- **تقارير ورسوم بيانية**:
  - استخدام `syncfusion_flutter_charts` لعرض:
    - تطور سعر الصرف عبر الزمن.
    - المبيعات حسب المنتج.
  - توليد تقرير PDF تفصيلي عن المبيعات والربح باستخدام حزمة `pdf` و`printing`.

- **نسخ احتياطي واستعادة**:
  - ضغط قاعدة البيانات ومجلد الصور في ملف ZIP.
  - استعادة الملف على جهاز آخر مع إعادة تحميل البيانات في الـ Cubit.

- **ثيم فاتح/غامق (Dark/Light Theme)**:
  - دعم `ThemeMode.system` ليتبع وضع النظام تلقائيًا.
  - استخدام `ColorScheme.fromSeed` وMaterial 3 لتصميم حديث.

- **دعم كامل للعربية و RTL**:
  - استخدام `Directionality(TextDirection.rtl)` على مستوى التطبيق.
  - خطوط عربية مدمجة (Noto Sans Arabic).

---

### 5️⃣ كيف تشغل المشروع محليًا؟

1. تأكد من تثبيت Flutter SDK.
2. نفّذ الأوامر التالية في مجلد المشروع:

```bash
flutter pub get
flutter run
```

3. التطبيق يدعم:
   - Android
   - iOS (مع إعداد Xcode مناسب)
   - Windows / macOS / Linux (حسب إعدادات Flutter لديك)

---

### 6️⃣ ملاحظات للتطوير المستقبلي

- استبدال `Get` بالكامل بالتنقل القياسي (`Navigator`) و`ScaffoldMessenger` لإكمال فصل المسؤوليات.
+- استخدام نماذج (Models) قوية (`Product`, `Offer`, `Sale`) بدل `Map<String, dynamic>` في كل الطبقات.

# inventory_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
