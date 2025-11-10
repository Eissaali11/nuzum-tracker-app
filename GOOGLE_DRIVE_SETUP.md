# 📁 إعداد Google Drive - Google Drive Setup

## 📋 معلومات المجلد

### رابط المجلد:
https://drive.google.com/drive/folders/1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe?usp=sharing

### Folder ID:
```
1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe
```

### Service Account Email:
```
nuzum-721@nuzum-477618.iam.gserviceaccount.com
```

### Project ID:
```
nuzum-477618
```

---

## 🔧 الإعداد في Backend (Replit)

### 1. تحديث Folder IDs في Backend

في ملف `backend/config.py` أو `backend/routes/requests.py`:

```python
# Google Drive Folder IDs
INVOICE_DRIVE_FOLDER_ID = "1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe"
ADVANCE_DRIVE_FOLDER_ID = "1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe"
CAR_WASH_DRIVE_FOLDER_ID = "1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe"
INSPECTION_DRIVE_FOLDER_ID = "1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe"
```

### 2. تحديث Endpoint لرفع على Drive

#### مثال: رفع صورة الفاتورة
```python
@app.route('/api/v1/requests/<int:request_id>/upload-invoice-image', methods=['POST'])
def upload_invoice_image(request_id):
    try:
        file = request.files['file']
        
        # رفع الملف على Google Drive
        file_metadata = {
            'name': f'invoice_{request_id}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.jpg',
            'parents': [INVOICE_DRIVE_FOLDER_ID]  # استخدام Folder ID
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

#### مثال: رفع صورة السلفة
```python
@app.route('/api/v1/requests/<int:request_id>/upload-advance-image', methods=['POST'])
def upload_advance_image(request_id):
    try:
        file = request.files['file']
        
        file_metadata = {
            'name': f'advance_{request_id}_{datetime.now().strftime("%Y%m%d_%H%M%S")}.jpg',
            'parents': [ADVANCE_DRIVE_FOLDER_ID]
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

### Service Account Email:
```
nuzum-721@nuzum-477618.iam.gserviceaccount.com
```

### 1. التحقق من أن Service Account لديه صلاحيات على المجلد

1. افتح رابط المجلد: https://drive.google.com/drive/folders/1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe
2. اضغط على "مشاركة" (Share)
3. أضف Service Account email: `nuzum-721@nuzum-477618.iam.gserviceaccount.com` كـ "Manager" أو "Editor"
4. تأكد من أن Service Account يمكنه الوصول للمجلد

### 2. التحقق من Google Drive API

1. افتح Google Cloud Console
2. تأكد من تفعيل Google Drive API
3. تأكد من أن Service Account لديه الصلاحيات المطلوبة

---

## 🧪 اختبار الرفع

### 1. اختبار من Backend مباشرة

```python
# test_upload.py
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
import json
import os

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

print(f"File ID: {result.get('id')}")
print(f"Drive URL: {result.get('webViewLink')}")
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
  }
}
```

---

## 📝 ملاحظات مهمة

### 1. Folder ID vs Folder Link
- **Folder ID**: `1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe` (يستخدم في الكود)
- **Folder Link**: `https://drive.google.com/drive/folders/1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe` (للمستخدمين)

### 2. الصلاحيات
- Service Account يجب أن يكون "Manager" أو "Editor" على المجلد
- لا يكفي أن يكون "Viewer"

### 3. Shared Drive vs My Drive
- إذا كان المجلد في Shared Drive، تأكد من أن Service Account عضو في Shared Drive
- إذا كان في My Drive، تأكد من أن Service Account لديه صلاحيات على المجلد

---

## 🔍 استكشاف الأخطاء

### المشكلة: خطأ 403 (Forbidden)
**الحل**: 
- تأكد من أن Service Account لديه صلاحيات على المجلد
- تأكد من أن Google Drive API مفعل

### المشكلة: خطأ 404 (Not Found)
**الحل**:
- تأكد من أن Folder ID صحيح
- تأكد من أن المجلد موجود

### المشكلة: لا يتم رفع الملفات
**الحل**:
- تحقق من الـ logs في Backend
- تحقق من أن Service Account صحيح
- تحقق من أن Google Drive API يعمل

---

## ✅ قائمة التحقق

- [x] Folder ID صحيح: `1AvaKUW2VKb9t4O4Dwo_KXTntBfDQ1IYe`
- [ ] Service Account (`nuzum-721@nuzum-477618.iam.gserviceaccount.com`) لديه صلاحيات على المجلد
- [ ] Google Drive API مفعل في Project: `nuzum-477618`
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

---

**آخر تحديث:** 2025-01-27

