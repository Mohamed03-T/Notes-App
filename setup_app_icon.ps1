# Android App Icon Setup Script

Write-Host "إعداد أيقونة التطبيق للأندرويد..." -ForegroundColor Green

# المسارات
$logoPath = "C:\Users\Lenovo\Documents\My Apps\note_app\assets\images\logo.png"
$androidResPath = "C:\Users\Lenovo\Documents\My Apps\note_app\android\app\src\main\res"

# التحقق من وجود الشعار
if (Test-Path $logoPath) {
    Write-Host "تم العثور على الشعار: $logoPath" -ForegroundColor Green
    
    # نسخ الشعار إلى مجلدات الأيقونات المختلفة
    $iconDirs = @(
        "$androidResPath\mipmap-mdpi",
        "$androidResPath\mipmap-hdpi", 
        "$androidResPath\mipmap-xhdpi",
        "$androidResPath\mipmap-xxhdpi",
        "$androidResPath\mipmap-xxxhdpi"
    )
    
    foreach ($dir in $iconDirs) {
        if (Test-Path $dir) {
            Copy-Item $logoPath "$dir\ic_launcher.png" -Force
            Write-Host "تم نسخ الأيقونة إلى: $dir" -ForegroundColor Yellow
        }
    }
    
    Write-Host "تم إعداد أيقونة التطبيق بنجاح!" -ForegroundColor Green
    Write-Host "ملاحظة: قد تحتاج إلى تغيير حجم الشعار ليناسب أحجام الأيقونات المختلفة" -ForegroundColor Cyan
} else {
    Write-Host "لم يتم العثور على الشعار في: $logoPath" -ForegroundColor Red
}

# إضافة أيقونة مستديرة أيضاً (Android 8.0+)
foreach ($dir in $iconDirs) {
    if (Test-Path $dir) {
        Copy-Item $logoPath "$dir\ic_launcher_round.png" -Force
    }
}

Write-Host "انتهى إعداد الأيقونات!" -ForegroundColor Green
