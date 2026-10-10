\# ShopGenie AI



ShopGenie AI is a smart inventory and billing application designed to help shopkeepers manage products, track stock, record customer bills, and monitor sales.



\## Technology Stack



\- \*\*Frontend:\*\* Flutter and Dart

\- \*\*Backend:\*\* Django REST Framework

\- \*\*Database:\*\* PostgreSQL

\- \*\*Computer Vision:\*\* OpenCV and PyTorch with MobileNetV3

\- \*\*Camera:\*\* Android mobile phone's built-in camera



\## Features



\- User registration and login

\- Product and inventory management

\- Manual product selection

\- Mobile camera-based product scanning

\- Computer vision-assisted product recognition

\- Smart billing and invoice management

\- Automatic stock updates during checkout

\- Sales analytics and reporting



\*\*Billing scope:\*\* ShopGenie AI records customer bills and tracks sales. UPI payment processing is not included in the current scope.



\## Project Architecture



The Flutter mobile application communicates with the Django REST Framework backend. The backend manages authentication, products, inventory, billing, analytics, and supported computer vision operations.



The PostgreSQL database stores application data. The computer vision components are maintained in the `cv\_engine/` directory.



The Android phone's built-in camera is intended to capture product images. The captured images can be sent to the backend or passed to the computer vision workflow, depending on the implemented integration.



\## Project Structure



```text

ShopGenie-AI/

├── app/

│   └── applet/             # Flutter mobile application

│       ├── lib/

│       │   ├── models/

│       │   ├── screens/

│       │   ├── services/

│       │   └── widgets/

│       ├── test/

│       ├── android/

│       └── pubspec.yaml

├── shopgenie/

│   └── backend/            # Django REST Framework backend

├── cv\_engine/              # Computer vision components

├── .env.example            # Example environment configuration

├── .gitignore

└── README.md

```



\## Prerequisites



Install the following tools:



\- Flutter SDK and Dart

\- Android Studio and Android SDK

\- Python compatible with the backend dependencies

\- PostgreSQL

\- Git



An Android emulator or physical Android phone can be used to run the Flutter application. For physical-device testing, grant camera permission when prompted.



\## Running the Flutter Application



1\. Open Android Studio.

2\. Open the Flutter project directory: `app/applet`.

3\. Wait for the project and Flutter dependencies to finish syncing.

4\. Ensure the Flutter SDK path is configured.

5\. Select an Android emulator or connected Android phone.

6\. Run the application.



Alternatively, use PowerShell from the repository root:



```powershell

cd app/applet

flutter pub get

flutter analyze

flutter test

flutter run

```



\## Running the Django Backend



1\. Navigate to `shopgenie/backend`.

2\. Activate the existing Python virtual environment.

3\. Configure the required environment variables in the local `.env` file.

4\. Ensure PostgreSQL is running and the database configuration is correct.

5\. Apply migrations if required.

6\. Start the Django development server.



Example PowerShell commands:



```powershell

cd shopgenie/backend

.\\.venv\\Scripts\\Activate.ps1

python manage.py check

python manage.py migrate

python manage.py runserver

```



Use the environment variables required by the existing backend configuration. Keep the actual `.env` file private and out of version control.



\## Mobile Camera Integration



ShopGenie AI is intended to use the Android phone's built-in camera rather than an external camera module.



The camera workflow should:



1\. Request camera permission.

2\. Capture an image of a product.

3\. Handle permission denial and camera errors.

4\. Pass the image to the configured recognition workflow.

5\. Use the recognition result in the product or inventory workflow.



The actual implementation depends on the Flutter camera integration and the existing backend and computer vision APIs. These steps describe the intended workflow; they do not guarantee that every step is already implemented.



\## Computer Vision



The `cv\_engine/` directory contains the computer vision components for product image processing and recognition. The planned technology stack includes OpenCV, PyTorch, and MobileNetV3.



The image-processing and recognition workflow should be verified against the current implementation before deployment.



\## Security



\- Never commit `.env` files containing real credentials.

\- Keep database passwords, API keys, and other secrets private.

\- Use authentication for protected backend endpoints.

\- Use HTTPS for production deployments.

\- Keep development settings separate from production settings.



\## Project Status



ShopGenie AI is under active development. The Flutter application, Django backend, PostgreSQL database, mobile camera integration, and computer vision workflow should be tested together as development progresses.



