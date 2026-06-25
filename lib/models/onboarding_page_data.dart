class OnboardingPageData {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

final List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    title: 'Salon Owner Dashboard',
    description: 'Monitor business growth, revenue, appointments and performance with real-time analytics.',
    imagePath: 'assets/images/dashboard.png',
  ),
  OnboardingPageData(
    title: 'Online Booking',
    description: 'Allow customers to book appointments anytime with an easy scheduling system.',
    imagePath: 'assets/images/booking.png',
  ),
  OnboardingPageData(
    title: 'Customer Management',
    description: 'Manage customer records, appointments and personalized services.',
    imagePath: 'assets/images/customer.png',
  ),
  OnboardingPageData(
    title: 'Payment Processing',
    description: 'Track payments and manage secure transactions effortlessly.',
    imagePath: 'assets/images/payment.png',
  ),
  OnboardingPageData(
    title: 'Service Management',
    description: 'Organize salon services, pricing and staff operations easily.',
    imagePath: 'assets/images/services.png',
  ),
];
