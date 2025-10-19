# Apache Reverse Proxy Setup Script

این اسکریپت به شما امکان می‌دهد تا یک **Reverse Proxy با Apache** از سرور A به سرور B راه‌اندازی کنید.  
اسکریپت دارای **منوی تعاملی** است و مسیرها و هدرهای کوکی را به درستی مدیریت می‌کند.


## ویژگی‌ها
- نصب خودکار Apache در صورت عدم وجود.
- فعال‌سازی ماژول‌های مورد نیاز (`proxy`, `proxy_http`, `rewrite`, `headers`).
- دریافت اطلاعات سرور مقصد (Server B) به صورت تعاملی:
  - IP
  - پورت
  - دامنه/Hostname
  - مسیر (Path)
- ایجاد VirtualHost برای پروکسی معکوس با پشتیبانی از اصلاح دامنه و مسیر کوکی.
- پشتیبان‌گیری از تنظیمات قبلی Apache.
- بررسی صحت کانفیگ قبل از راه‌اندازی.
- فعال‌سازی خودکار سرویس Apache در زمان بوت سیستم.


## پیش‌نیازها
- سیستم عامل: **Debian / Ubuntu**
- دسترسی **root** یا استفاده از `sudo`
- اتصال اینترنت برای نصب بسته‌ها



## نحوه اجرا

1. دستور زیر را در خط فرمان اجرا کنید:

```bash
curl -sSL https://raw.githubusercontent.com/Emmanuel-RCL/apache-reverse-proxy/main/reverse_proxy_setup.sh | sudo bash
```
