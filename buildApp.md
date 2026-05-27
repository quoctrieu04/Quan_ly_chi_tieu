B1: tăng version trong .yaml
B2 : flutter build appbundle --release
B3 sau đó copy file "build/app/outputs/bundle/release/app-release.aab" .aab và gg console play
python3 train_model.py || 
snapshot tháng: php artisan forecast:snapshot --source_year=2026 --source_month=5 --user_id=17 --force
python3 train_model_weekly.py
ls -l storage/app/models/weekly_linreg_coeffs.json
php artisan forecast:weekly-snapshot --source-week-start=YYYY-MM-DD --user-id=USER_ID --force
 mô hình dùng 3 tháng chi tiêu gần nhất để dự đoán. và đến ngày cuối cùng của thasg hiện tại mới đưa ra dự đoán