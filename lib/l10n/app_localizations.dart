import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = 
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // App
      'appName': 'Potato Timer',
      
      // Navigation
      'home': 'Home',
      'explore': 'Explore',
      'inspiration': 'Inspiration',
      'profile': 'Profile',
      
      // Login
      'welcome': 'Welcome',
      'loginWithPhone': 'Login with Phone',
      'loginSuccess': 'Login successful!',
      'loginFailed': 'Login failed',
      'logout': 'Logout',
      'logoutConfirm': 'Are you sure you want to logout?',
      
      // Goals
      'goals': 'Goals',
      'myGoals': 'My Goals',
      'createGoal': 'Create Goal',
      'editGoal': 'Edit Goal',
      'habit': 'Habit',
      'mainTask': 'Main Task',
      'goalTitle': 'Goal Title',
      'goalDescription': 'Description (optional)',
      'goalType': 'Goal Type',
      'reminderTime': 'Reminder Time',
      'enableTimer': 'Enable Timer',
      'duration': 'Duration',
      'minutes': 'minutes',
      'hours': 'hours',
      'totalHours': 'Total Hours',
      'streakDays': 'Streak Days',
      'completedDays': 'Completed Days',
      'progress': 'Progress',
      'noGoals': 'No goals yet',
      'createFirstGoal': 'Create your first goal',
      'mainTaskLimit': 'Only one active main task allowed',
      'publicGoal': 'Make it public',
      'morningReminder': 'Morning Reminder',
      'afternoonReminder': 'Afternoon Reminder',
      'sessionDuration': 'Session Duration',
      
      // Motivations
      'motivations': 'Motivations',
      'myMotivations': 'My Motivations',
      'createMotivation': 'Create Motivation',
      'editMotivation': 'Edit Motivation',
      'positive': 'Positive',
      'negative': 'Negative',
      'motivationType': 'Motivation Type',
      'positiveDesc': 'Things you aspire to achieve',
      'negativeDesc': 'Consequences of not achieving your goal',
      'content': 'Content',
      'addMedia': 'Add Media',
      'addTags': 'Add Tags',
      'publicMotivation': 'Make it public',
      'noMotivations': 'No motivations yet',
      'createFirstMotivation': 'Create your first motivation',
      
      // Actions
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'complete': 'Complete',
      'postpone': 'Postpone',
      'start': 'Start',
      'pause': 'Pause',
      'resume': 'Resume',
      'finish': 'Finish',
      'confirm': 'Confirm',
      'back': 'Back',
      'next': 'Next',
      'skip': 'Skip',
      'done': 'Done',
      'like': 'Like',
      'favorite': 'Favorite',
      'share': 'Share',
      
      // Timer
      'timer': 'Timer',
      'timeRemaining': 'Time Remaining',
      'timerComplete': 'Timer Complete!',
      'keepGoing': 'Keep going!',
      
      // Calm Page
      'calmMode': 'Calm Mode',
      'calmModeDesc': 'Take 5 minutes to do nothing but your task',
      'calmModeHint': 'Let your mind calm down...',
      'breathe': 'Breathe',
      
      // Explore
      'exploreTrending': 'Trending',
      'exploreRecent': 'Recent',
      'exploreGoals': 'Goals',
      'exploreMotivations': 'Motivations',
      'viewAll': 'View All',
      'noPublicContent': 'No public content yet',
      
      // Profile
      'settings': 'Settings',
      'editProfile': 'Edit Profile',
      'nickname': 'Nickname',
      'favorites': 'Favorites',
      'statistics': 'Statistics',
      'totalGoals': 'Total Goals',
      'totalMotivations': 'Total Motivations',
      'longestStreak': 'Longest Streak',
      'days': 'days',
      
      // Notifications
      'notifications': 'Notifications',
      'reminderTitle': 'Time to work on your goal!',
      'habitReminder': 'Time for {goal}',
      'mainTaskReminder': 'Continue working on {goal}',
      'postponeReminder': 'Don\'t forget: {goal}',
      
      // Tags
      'tags': 'Tags',
      'popularTags': 'Popular Tags',
      'customTags': 'Custom Tags',
      'addTag': 'Add Tag',
      
      // Errors
      'error': 'Error',
      'networkError': 'Network error, please try again',
      'loadFailed': 'Failed to load',
      'saveFailed': 'Failed to save',
      'deleteFailed': 'Failed to delete',
      'retry': 'Retry',
      
      // Misc
      'loading': 'Loading...',
      'empty': 'Nothing here',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'thisWeek': 'This Week',
      'selectTime': 'Select Time',
      'selectDate': 'Select Date',
      'selectMotivations': 'Select Motivations',
      'selected': 'Selected',
      'all': 'All',
    },
    'zh': {
      // App
      'appName': '土豆时钟',
      
      // Navigation
      'home': '首页',
      'explore': '探索',
      'inspiration': '灵感',
      'profile': '我的',
      
      // Login
      'welcome': '欢迎',
      'loginWithPhone': '一键登录',
      'loginSuccess': '登录成功！',
      'loginFailed': '登录失败',
      'logout': '退出登录',
      'logoutConfirm': '确定要退出登录吗？',
      
      // Goals
      'goals': '目标',
      'myGoals': '我的目标',
      'createGoal': '创建目标',
      'editGoal': '编辑目标',
      'habit': '微习惯',
      'mainTask': '主线任务',
      'goalTitle': '目标标题',
      'goalDescription': '描述（可选）',
      'goalType': '目标类型',
      'reminderTime': '提醒时间',
      'enableTimer': '启用计时器',
      'duration': '时长',
      'minutes': '分钟',
      'hours': '小时',
      'totalHours': '总时长',
      'streakDays': '连续天数',
      'completedDays': '完成天数',
      'progress': '进度',
      'noGoals': '还没有目标',
      'createFirstGoal': '创建你的第一个目标',
      'mainTaskLimit': '只能有一个进行中的主线任务',
      'publicGoal': '公开目标',
      'morningReminder': '上午提醒',
      'afternoonReminder': '下午提醒',
      'sessionDuration': '单次时长',
      
      // Motivations
      'motivations': '激励内容',
      'myMotivations': '我的激励',
      'createMotivation': '创建激励',
      'editMotivation': '编辑激励',
      'positive': '正向激励',
      'negative': '反向激励',
      'motivationType': '激励类型',
      'positiveDesc': '完成目标后能取得的美好结果',
      'negativeDesc': '不完成目标的后果，或让你愤怒羞耻的事',
      'content': '内容',
      'addMedia': '添加图片/视频',
      'addTags': '添加标签',
      'publicMotivation': '公开内容',
      'noMotivations': '还没有激励内容',
      'createFirstMotivation': '创建你的第一条激励',
      
      // Actions
      'save': '保存',
      'cancel': '取消',
      'delete': '删除',
      'edit': '编辑',
      'complete': '完成',
      'postpone': '推迟',
      'start': '开始',
      'pause': '暂停',
      'resume': '继续',
      'finish': '结束',
      'confirm': '确认',
      'back': '返回',
      'next': '下一步',
      'skip': '跳过',
      'done': '完成',
      'like': '点赞',
      'favorite': '收藏',
      'share': '分享',
      
      // Timer
      'timer': '计时器',
      'timeRemaining': '剩余时间',
      'timerComplete': '计时完成！',
      'keepGoing': '继续加油！',
      
      // Calm Page
      'calmMode': '冷静模式',
      'calmModeDesc': '五分钟内除了目标什么都不做',
      'calmModeHint': '让大脑平静下来...',
      'breathe': '深呼吸',
      
      // Explore
      'exploreTrending': '热门',
      'exploreRecent': '最新',
      'exploreGoals': '目标',
      'exploreMotivations': '激励',
      'viewAll': '查看全部',
      'noPublicContent': '暂无公开内容',
      
      // Profile
      'settings': '设置',
      'editProfile': '编辑资料',
      'nickname': '昵称',
      'favorites': '我的收藏',
      'statistics': '统计',
      'totalGoals': '目标总数',
      'totalMotivations': '激励总数',
      'longestStreak': '最长连续',
      'days': '天',
      
      // Notifications
      'notifications': '通知',
      'reminderTitle': '是时候开始了！',
      'habitReminder': '该做 {goal} 了',
      'mainTaskReminder': '继续 {goal}',
      'postponeReminder': '别忘了：{goal}',
      
      // Tags
      'tags': '标签',
      'popularTags': '热门标签',
      'customTags': '自定义标签',
      'addTag': '添加标签',
      
      // Errors
      'error': '错误',
      'networkError': '网络错误，请重试',
      'loadFailed': '加载失败',
      'saveFailed': '保存失败',
      'deleteFailed': '删除失败',
      'retry': '重试',
      
      // Misc
      'loading': '加载中...',
      'empty': '空空如也',
      'today': '今天',
      'yesterday': '昨天',
      'thisWeek': '本周',
      'selectTime': '选择时间',
      'selectDate': '选择日期',
      'selectMotivations': '选择激励内容',
      'selected': '已选择',
      'all': '全部',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }

  String format(String key, Map<String, String> args) {
    String text = get(key);
    args.forEach((argKey, value) {
      text = text.replaceAll('{$argKey}', value);
    });
    return text;
  }

  // 快捷访问器
  String get appName => get('appName');
  String get home => get('home');
  String get explore => get('explore');
  String get inspiration => get('inspiration');
  String get profile => get('profile');
  String get welcome => get('welcome');
  String get loginWithPhone => get('loginWithPhone');
  String get loginSuccess => get('loginSuccess');
  String get loginFailed => get('loginFailed');
  String get logout => get('logout');
  String get logoutConfirm => get('logoutConfirm');
  String get goals => get('goals');
  String get myGoals => get('myGoals');
  String get createGoal => get('createGoal');
  String get editGoal => get('editGoal');
  String get habit => get('habit');
  String get mainTask => get('mainTask');
  String get goalTitle => get('goalTitle');
  String get goalDescription => get('goalDescription');
  String get goalType => get('goalType');
  String get reminderTime => get('reminderTime');
  String get enableTimer => get('enableTimer');
  String get duration => get('duration');
  String get minutes => get('minutes');
  String get hours => get('hours');
  String get totalHours => get('totalHours');
  String get streakDays => get('streakDays');
  String get completedDays => get('completedDays');
  String get progress => get('progress');
  String get noGoals => get('noGoals');
  String get createFirstGoal => get('createFirstGoal');
  String get mainTaskLimit => get('mainTaskLimit');
  String get publicGoal => get('publicGoal');
  String get morningReminder => get('morningReminder');
  String get afternoonReminder => get('afternoonReminder');
  String get sessionDuration => get('sessionDuration');
  String get motivations => get('motivations');
  String get myMotivations => get('myMotivations');
  String get createMotivation => get('createMotivation');
  String get editMotivation => get('editMotivation');
  String get positive => get('positive');
  String get negative => get('negative');
  String get motivationType => get('motivationType');
  String get positiveDesc => get('positiveDesc');
  String get negativeDesc => get('negativeDesc');
  String get content => get('content');
  String get addMedia => get('addMedia');
  String get addTags => get('addTags');
  String get publicMotivation => get('publicMotivation');
  String get noMotivations => get('noMotivations');
  String get createFirstMotivation => get('createFirstMotivation');
  String get save => get('save');
  String get cancel => get('cancel');
  String get delete => get('delete');
  String get edit => get('edit');
  String get complete => get('complete');
  String get postpone => get('postpone');
  String get start => get('start');
  String get pause => get('pause');
  String get resume => get('resume');
  String get finish => get('finish');
  String get confirm => get('confirm');
  String get back => get('back');
  String get next => get('next');
  String get skip => get('skip');
  String get done => get('done');
  String get like => get('like');
  String get favorite => get('favorite');
  String get share => get('share');
  String get timer => get('timer');
  String get timeRemaining => get('timeRemaining');
  String get timerComplete => get('timerComplete');
  String get keepGoing => get('keepGoing');
  String get calmMode => get('calmMode');
  String get calmModeDesc => get('calmModeDesc');
  String get calmModeHint => get('calmModeHint');
  String get breathe => get('breathe');
  String get exploreTrending => get('exploreTrending');
  String get exploreRecent => get('exploreRecent');
  String get exploreGoals => get('exploreGoals');
  String get exploreMotivations => get('exploreMotivations');
  String get viewAll => get('viewAll');
  String get noPublicContent => get('noPublicContent');
  String get settings => get('settings');
  String get editProfile => get('editProfile');
  String get nickname => get('nickname');
  String get favorites => get('favorites');
  String get statistics => get('statistics');
  String get totalGoals => get('totalGoals');
  String get totalMotivations => get('totalMotivations');
  String get longestStreak => get('longestStreak');
  String get days => get('days');
  String get notifications => get('notifications');
  String get reminderTitle => get('reminderTitle');
  String get tags => get('tags');
  String get popularTags => get('popularTags');
  String get customTags => get('customTags');
  String get addTag => get('addTag');
  String get error => get('error');
  String get networkError => get('networkError');
  String get loadFailed => get('loadFailed');
  String get saveFailed => get('saveFailed');
  String get deleteFailed => get('deleteFailed');
  String get retry => get('retry');
  String get loading => get('loading');
  String get empty => get('empty');
  String get today => get('today');
  String get yesterday => get('yesterday');
  String get thisWeek => get('thisWeek');
  String get selectTime => get('selectTime');
  String get selectDate => get('selectDate');
  String get selectMotivations => get('selectMotivations');
  String get selected => get('selected');
  String get all => get('all');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}


