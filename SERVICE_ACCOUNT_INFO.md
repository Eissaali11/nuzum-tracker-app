# 🔐 معلومات Service Account - Service Account Information

## 📋 معلومات Service Account

### Service Account Email:
```
nuzum-721@nuzum-477618.iam.gserviceaccount.com
```

### Project ID:
```
nuzum-477618
```

### Project Name:
```
nuzum
```

---

## 📁 Google Drive Folder

### Folder ID:
```
1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe
```

### Folder Link:
https://drive.google.com/drive/folders/1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe?usp=sharing

---

## 🔧 الإعداد في Backend (Replit)

### ⚠️ تحذير أمني مهم

**لا تحفظ Service Account JSON في الكود!**
- Private Key يمكن استخراجها من الكود بسهولة
- استخدم Replit Secrets فقط
- لا ترفع Private Key على GitHub

---

### 1. إضافة Service Account إلى Replit Secrets

في Replit، أضف Service Account JSON في Secrets:

#### الطريقة الصحيحة:

1. افتح Replit
2. اذهب إلى "Secrets" (في القائمة الجانبية)
3. أضف Secret جديد:
   - **Key**: `GOOGLE_SERVICE_ACCOUNT`
   - **Value**: (انسخ Service Account JSON كاملاً - انظر أدناه)

#### Service Account JSON (للنسخ):

**⚠️ تحذير أمني**: Private Key محذوف من هذا الملف لأسباب أمنية. استخدم Service Account JSON الكامل من Google Cloud Console.

**📋 معلومات Service Account:**
- **Project ID**: `nuzum-477618`
- **Service Account Email**: `nuzum-721@nuzum-477618.iam.gserviceaccount.com`
- **Private Key ID**: `4ef8877f3c0ac1b316594e019ed97e4eb4f03e68`
- **Client ID**: `108366574147056527902`

**📝 Service Account JSON Template:**

احصل على Service Account JSON الكامل من Google Cloud Console واستخدمه في Replit Secrets:

```json
{
  "type": "service_account",
  "project_id": "nuzum-477618",
  "private_key_id": "[YOUR_PRIVATE_KEY_ID]",
  "private_key": "-----BEGIN PRIVATE KEY-----\n[YOUR_PRIVATE_KEY_HERE]\n-----END PRIVATE KEY-----\n",
  "client_email": "nuzum-721@nuzum-477618.iam.gserviceaccount.com",
  "client_id": "[YOUR_CLIENT_ID]",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/nuzum-721%40nuzum-477618.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
```

**⚠️ مهم**: 
- احصل على Service Account JSON الكامل من Google Cloud Console
- انسخ JSON كاملاً (بما في ذلك Private Key)
- الصقه في Replit Secrets كـ String واحد
- لا تحفظه في أي ملف في الكود

### 2. تحديث Folder IDs في Backend

```python
# في backend/config.py
INVOICE_DRIVE_FOLDER_ID = "1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe"
ADVANCE_DRIVE_FOLDER_ID = "1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe"
CAR_WASH_DRIVE_FOLDER_ID = "1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe"
INSPECTION_DRIVE_FOLDER_ID = "1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe"
```

### 3. مثال كود Backend

```python
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
import json
import os

# تحميل Service Account من Replit Secrets
SERVICE_ACCOUNT_INFO = json.loads(os.environ['GOOGLE_SERVICE_ACCOUNT'])

SCOPES = ['https://www.googleapis.com/auth/drive.file']
credentials = service_account.Credentials.from_service_account_info(
    SERVICE_ACCOUNT_INFO,
    scopes=SCOPES
)
drive_service = build('drive', 'v3', credentials=credentials)

# Folder ID
INVOICE_DRIVE_FOLDER_ID = "1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe"

@app.route('/api/v1/requests/<int:request_id>/upload-invoice-image', methods=['POST'])
def upload_invoice_image(request_id):
    try:
        file = request.files['file']
        
        file_metadata = {
            'name': f'invoice_{request_id}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.jpg',
            'parents': [INVOICE_DRIVE_FOLDER_ID]
        }
        
        media = MediaFileUpload(file, mimetype=file.content_type)
        result = drive_service.files().create(
            body=file_metadata,
            media_body=media,
            fields='id,webViewLink'
        ).execute()
        
        return jsonify({
            'success': True,
            'drive_url': result.get('webViewLink'),
            'file_id': result.get('id')
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
```

---

## ✅ التحقق من الصلاحيات

### 1. إضافة Service Account إلى المجلد

1. افتح رابط المجلد: https://drive.google.com/drive/folders/1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe
2. اضغط على "مشاركة" (Share)
3. أضف Service Account email: `nuzum-721@nuzum-477618.iam.gserviceaccount.com`
4. اختر الصلاحية: "Manager" أو "Editor"
5. اضغط "إرسال" (Send)

### 2. التحقق من Google Drive API

1. افتح Google Cloud Console: https://console.cloud.google.com/
2. اختر Project: `nuzum-477618`
3. اذهب إلى "APIs & Services" > "Library"
4. ابحث عن "Google Drive API"
5. تأكد من أنه مفعل (Enabled)

### 3. التحقق من Service Account

1. اذهب إلى "IAM & Admin" > "Service Accounts"
2. ابحث عن: `nuzum-721@nuzum-477618.iam.gserviceaccount.com`
3. تأكد من وجوده
4. تحقق من الصلاحيات الممنوحة

---

## 🧪 اختبار الرفع

### 1. اختبار من Backend

```python
# test_upload.py
import os
import json
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# تحميل Service Account
SERVICE_ACCOUNT_INFO = json.loads(os.environ['GOOGLE_SERVICE_ACCOUNT'])
credentials = service_account.Credentials.from_service_account_info(
    SERVICE_ACCOUNT_INFO,
    scopes=['https://www.googleapis.com/auth/drive.file']
)
drive_service = build('drive', 'v3', credentials=credentials)

# رفع ملف تجريبي
file_metadata = {
    'name': 'test_file.jpg',
    'parents': ['1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe']
}

media = MediaFileUpload('test_file.jpg', mimetype='image/jpeg')
result = drive_service.files().create(
    body=file_metadata,
    media_body=media,
    fields='id,webViewLink'
).execute()

print(f"✅ File ID: {result.get('id')}")
print(f"✅ Drive URL: {result.get('webViewLink')}")
```

### 2. اختبار من Flutter

```dart
// اختبار رفع فاتورة
final request = InvoiceRequest(
  employeeId: 123,
  vendorName: 'مورد تجريبي',
  amount: 1000.0,
  imagePath: '/path/to/invoice.jpg',
);

final result = await RequestsApiService.createInvoice(
  request,
  onProgress: (sent, total) {
    print('Progress: ${(sent / total * 100).toStringAsFixed(1)}%');
  },
);

if (result['success'] == true) {
  print('✅ Request ID: ${result['data']['request_id']}');
  if (result['data']['drive_url'] != null) {
    print('✅ Drive URL: ${result['data']['drive_url']}');
    // يجب أن يكون الرابط مثل:
    // https://drive.google.com/file/d/...
  }
}
```

---

## 🔍 استكشاف الأخطاء

### المشكلة: خطأ 403 (Forbidden)
**الأسباب المحتملة**:
- Service Account ليس لديه صلاحيات على المجلد
- Google Drive API غير مفعل

**الحل**:
1. تأكد من إضافة Service Account إلى المجلد كـ "Manager" أو "Editor"
2. تأكد من تفعيل Google Drive API في Google Cloud Console

### المشكلة: خطأ 404 (Not Found)
**الأسباب المحتملة**:
- Folder ID غير صحيح
- المجلد غير موجود

**الحل**:
1. تحقق من Folder ID: `1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe`
2. تأكد من أن المجلد موجود

### المشكلة: لا يتم رفع الملفات
**الأسباب المحتملة**:
- Service Account JSON غير صحيح
- Replit Secrets غير مضبوطة بشكل صحيح

**الحل**:
1. تحقق من Service Account JSON في Replit Secrets
2. تحقق من الـ logs في Backend
3. تأكد من أن Service Account صحيح

---

## 📝 ملاحظات مهمة

### 1. الأمان
- ✅ **لا تحفظ Service Account JSON في الكود**
- ✅ **استخدم Replit Secrets فقط**
- ✅ **لا تشارك Private Key**

### 2. الصلاحيات
- Service Account يجب أن يكون "Manager" أو "Editor" على المجلد
- لا يكفي أن يكون "Viewer"

### 3. Scopes
- المطلوب: `https://www.googleapis.com/auth/drive.file`
- هذا الـ scope يسمح بإنشاء وتعديل الملفات فقط

---

## ✅ قائمة التحقق النهائية

- [x] Folder ID: `1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe`
- [x] Service Account Email: `nuzum-721@nuzum-477618.iam.gserviceaccount.com`
- [x] Project ID: `nuzum-477618`
- [ ] Service Account لديه صلاحيات على المجلد
- [ ] Google Drive API مفعل
- [ ] Service Account JSON في Replit Secrets
- [ ] Backend endpoint يعمل بشكل صحيح
- [ ] Flutter يرسل الطلبات بشكل صحيح
- [ ] الملفات تُرفع على Drive بنجاح
- [ ] `drive_url` يُعاد في الـ response

---

## 📞 الدعم

إذا واجهت أي مشاكل:
1. تحقق من الـ logs في Backend
2. تحقق من صلاحيات Service Account
3. تحقق من أن Folder ID صحيح
4. تحقق من أن Google Drive API مفعل
5. تحقق من أن Service Account JSON صحيح في Replit Secrets

---

**آخر تحديث:** 2025-01-27

