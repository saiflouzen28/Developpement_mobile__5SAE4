class AppRoute {
  // ============================================================
  //                   AUTHENTIFICATION
  // ============================================================
  static const String signIn = '/signIn';
  static const String signUp = '/signUp';
  static const String emailVerification = '/emailVerification';

  // ============================================================
  //                   UTILISATEUR / APP PRINCIPALE
  // ============================================================
  static const String home = '/home';
  static const String events = '/events';
  static const String eventDetails = '/eventDetails';
  static const String schedule = '/schedule';
  static const String profile = '/profile';
  static const String quizze = '/quizze';
  static const String PackStoreScreen = '/PackStoreScreen';


  static const String postsList = '/postsList';
  static const String createPost = '/createPost';
  static const String detailsPost = '/detailsPost';
  static const String notifications = '/notifications';
  static const String courses = '/courses';
  static const String courseDetails = '/courses/details';

  // ============================================================
  //                        ADMIN DASHBOARD
  // ============================================================
  static const String adminDashboard = '/adminDashboard';

  // --- Gestion des Cours ---
  static const String manageCourses = '/admin/manageCourses';
  static const String addEditCourse = '/admin/addEditCourse';

  // --- Gestion des Leçons ---
  static const String manageLessons = '/admin/manageLessons';
  static const String addEditLesson = '/admin/addEditLesson';
}
