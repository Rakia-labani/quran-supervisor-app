// lib/screens/students_screen.dart

import 'package:flutter/material.dart';

import 'dart:async';

import '../constants/constants.dart';
import '../services/services.dart';
import '../services/api_exception.dart';
import '../services/local_cache.dart';
import '../services/connectivity_service.dart';
import '../widgets/app_bar.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sort_chip.dart';
import '../widgets/student_card.dart';
import '../widgets/add_parts_dialog.dart';

// خيارات الفرز المتاحة لقائمة الطالبات
enum _SortMode { none, nameAsc, partsDesc, partsAsc }

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  _StudentsScreenState createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  // مفتاح الكاش المحلي لصفحة الطالبات الأولى
  static const String _cacheKey = 'cache_students_page1';

  // متغيرات الحالة
  bool _isLoading = true;
  bool _isLoadingMore = false;
  List<dynamic> _students = [];
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalRecords = 0;
  String? _nextPageUrl;
  String _errorMessage = '';

  // ✅ حالة الاتصال بالإنترنت وآخر وقت تحديث للبيانات
  bool _isOffline = false;
  DateTime? _lastUpdated;
  StreamSubscription<bool>? _connectivitySub;

  // ✅ حالة البحث والفرز
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _SortMode _sortMode = _SortMode.none;

  // متحكم التمرير للقائمة
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitial();

    // ✅ مراقبة حالة الاتصال — لما يرجع النت بعد انقطاع، نجدّد البيانات تلقائياً
    _connectivitySub = ConnectivityService.onStatusChange.listen((connected) {
      final wasOffline = _isOffline;
      if (mounted) setState(() => _isOffline = !connected);
      if (wasOffline && connected) {
        _fetchStudents();
      }
    });

    // إضافة مستمع للتمرير للكشف عن الوصول لنهاية القائمة
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _loadMoreStudents();
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  // ✅ أول تحميل: نعرض الكاش المحفوظ فوراً (لو موجود) وبنفس الوقت نجيب
  // نسخة حديثة من السيرفر بالخلفية (نمط Stale-While-Revalidate)
  Future<void> _loadInitial() async {
    final cached = await LocalCache.read(_cacheKey);
    final cachedAt = await LocalCache.lastUpdated(_cacheKey);

    if (cached != null && mounted) {
      setState(() {
        _students = cached['students'] ?? [];
        _currentPage = cached['current_page'] ?? 1;
        _lastPage = cached['last_page'] ?? 1;
        _totalRecords = cached['total_records'] ?? 0;
        _nextPageUrl = cached['next_page_url'];
        _lastUpdated = cachedAt;
        _isLoading = false; // في بيانات لنعرضها فوراً، ما في داعي للـ Skeleton
      });
    }

    await _fetchStudents();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  // جلب بيانات الطالبات
  Future<void> _fetchStudents({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final response = await ApiService.getStudents(page: 1);

      // ✅ حفظ آخر رد ناجح بالكاش المحلي حتى يظهر فوراً بالمرة الجاية
      // أو لو انقطع النت
      await LocalCache.save(_cacheKey, response);

      setState(() {
        _students = response['students'];
        _currentPage = response['current_page'];
        _lastPage = response['last_page'];
        _totalRecords = response['total_records'];
        _nextPageUrl = response['next_page_url'];
        _isLoading = false;
        _errorMessage = '';
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // ✅ لو عنا بيانات محفوظة أصلاً (من الكاش)، ما منعرض شاشة خطأ كاملة
        // — منسيب البيانات ظاهرة ومنعرض بانر خفيف بس فوقها
        _errorMessage = _getErrorMessage(e);
      });
    }
  }

  // تحميل المزيد من الطالبات
  Future<void> _loadMoreStudents() async {
    // التحقق من وجود المزيد من الصفحات
    if (_currentPage >= _lastPage || _isLoadingMore || _nextPageUrl == null) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await ApiService.getStudents(page: _currentPage + 1);

      setState(() {
        _students.addAll(response['students']);
        _currentPage = response['current_page'];
        _lastPage = response['last_page'];
        _totalRecords = response['total_records'];
        _nextPageUrl = response['next_page_url'];
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });

      // عرض رسالة خطأ للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getErrorMessage(e)),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  // استخراج رسالة الخطأ
  String _getErrorMessage(dynamic error) => userMessageFor(error);

  // تحديث القائمة بالسحب للأسفل
  Future<void> _refresh() async {
    await _fetchStudents(isRefresh: true);
  }

  // ✅ فتح شاشة إضافة طالبة، وتحديث القائمة تلقائياً بعد الرجوع منها
  // (بغض النظر شو رجّعت الشاشة، لأنه أبسط وأضمن طريقة نضمن فيها ظهور
  // الطالبة الجديدة فوراً بدون ما تحتاجي تسحبي للتحديث يدوياً)
  Future<void> _openAddStudent() async {
    await Navigator.pushNamed(context, AppRoutes.addStudent);
    if (mounted) _fetchStudents();
  }

  // ✅ القائمة الظاهرة فعلياً بعد تطبيق البحث والفرز
  // (البحث بيدور بين الطالبات المحمّلة لحد هلق، وكل ما تنزلي وتحمّلي أكتر
  // بينضاف نتائج جديدة تلقائياً لأنها منبنية على _students مباشرة)
  List<dynamic> get _visibleStudents {
    var list = List<dynamic>.from(_students);

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((s) => s['name'].toString().toLowerCase().contains(query))
          .toList();
    }

    switch (_sortMode) {
      case _SortMode.nameAsc:
        list.sort(
          (a, b) => a['name'].toString().compareTo(b['name'].toString()),
        );
        break;
      case _SortMode.partsDesc:
        list.sort((a, b) => b['number'].compareTo(a['number']));
        break;
      case _SortMode.partsAsc:
        list.sort((a, b) => a['number'].compareTo(b['number']));
        break;
      case _SortMode.none:
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppStrings.students,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      // ✅ زر عائم واضح لإضافة طالبة، دايماً بمتناول اليد وهي عم تتصفح
      // القائمة، بدل ما تضطر ترجع عالرئيسية كل مرة بدها تضيف طالبة
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddStudent,
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة طالبة'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoading(child: SkeletonListView(count: 6));
    }

    // ✅ نعرض شاشة الخطأ الكاملة بس لو ما في ولا بيانات نعرضها (لا من
    // السيرفر ولا من الكاش). إذا في بيانات (حتى لو قديمة)، منسيبها ظاهرة
    // ومنكتفي ببانر خفيف فوق (شوفي تحت بالـ RefreshIndicator)
    if (_errorMessage.isNotEmpty && _students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: AppDimensions.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد طالبات لعرضها',
              style: TextStyle(
                fontSize: AppDimensions.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _refresh, child: const Text('تحديث')),
            const SizedBox(height: 8),
            // ✅ لما القائمة فاضية بالأصل، منسهّل كمان الوصول لإضافة أول
            // طالبة من نفس المكان بدل ما نخليها تدور على الزر العائم
            TextButton.icon(
              onPressed: _openAddStudent,
              icon: const Icon(Icons.person_add),
              label: const Text('إضافة طالبة جديدة'),
            ),
          ],
        ),
      );
    }

    final visibleStudents = _visibleStudents;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Column(
        children: [
          // ✅ بانر خفيف لما نكون عم نعرض بيانات قديمة (كاش) بسبب انقطاع
          // النت أو فشل آخر تحديث
          if (_isOffline || _errorMessage.isNotEmpty)
            OfflineBanner(
              message: _isOffline
                  ? null // الرسالة الافتراضية "غير متصلة بالإنترنت..."
                  : 'تعذّر تحديث البيانات، آخر نسخة محفوظة معروضة',
            ),
          // معلومات الصفحة
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            color: AppColors.surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الطالبات: $_totalRecords',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'الصفحة: $_currentPage/$_lastPage',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSizeMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (_lastUpdated != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'آخر تحديث: ${_formatTime(_lastUpdated!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ✅ مربع البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingMedium,
              AppDimensions.paddingMedium,
              AppDimensions.paddingMedium,
              0,
            ),
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'ابحثي باسم الطالبة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      ),
                filled: true,
                fillColor: AppColors.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ✅ خيارات الفرز
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingSmall,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('الترتيب الافتراضي', _SortMode.none),
                  const SizedBox(width: 8),
                  _buildSortChip('الاسم (أ-ي)', _SortMode.nameAsc),
                  const SizedBox(width: 8),
                  _buildSortChip('الأكثر حفظاً', _SortMode.partsDesc),
                  const SizedBox(width: 8),
                  _buildSortChip('الأقل حفظاً', _SortMode.partsAsc),
                ],
              ),
            ),
          ),

          // ✅ عدد نتائج البحث لما يكون في بحث فعّال
          if (_searchQuery.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'النتائج: ${visibleStudents.length}',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

          // قائمة الطالبات
          Expanded(
            child: visibleStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 56,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'ما في طالبة بهيك اسم',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSizeMedium,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    // ✅ مسافة إضافية بالأسفل حتى الزر العائم ما يغطي آخر
                    // كرت بالقائمة
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.paddingMedium,
                      AppDimensions.paddingMedium,
                      AppDimensions.paddingMedium,
                      88,
                    ),
                    itemCount:
                        visibleStudents.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // عرض مؤشر التحميل في نهاية القائمة
                      if (index == visibleStudents.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final student = visibleStudents[index];
                      return StudentCard(
                        student: student,
                        onAddParts: () => _showAddPartsDialog(student),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, _SortMode mode) {
    return SortChip(
      label: label,
      selected: _sortMode == mode,
      onSelected: () => setState(() => _sortMode = mode),
    );
  }

  Future<void> _showAddPartsDialog(Map<String, dynamic> student) async {
    final updated = await showAddPartsDialog(context, student);
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حفظ ${student['name']}'),
          backgroundColor: AppColors.successColor,
        ),
      );
      _fetchStudents(); // تحديث القائمة بالخلفية
    }
  }

  // تنسيق وقت بسيط (HH:mm) بدون الحاجة لمكتبة intl
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
