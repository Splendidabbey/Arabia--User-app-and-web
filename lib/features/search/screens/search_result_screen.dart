import 'package:flutter/material.dart';
import 'package:flutter_restaurant/common/providers/product_provider.dart';
import 'package:flutter_restaurant/common/providers/theme_provider.dart';
import 'package:flutter_restaurant/common/widgets/custom_alert_dialog_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_asset_image_widget.dart';
import 'package:flutter_restaurant/common/widgets/custom_text_field_widget.dart';
import 'package:flutter_restaurant/common/widgets/footer_widget.dart';
import 'package:flutter_restaurant/common/widgets/no_data_widget.dart';
import 'package:flutter_restaurant/common/widgets/paginated_list_widget.dart';
import 'package:flutter_restaurant/common/widgets/product_shimmer_widget.dart';
import 'package:flutter_restaurant/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_restaurant/features/category/providers/category_provider.dart';
import 'package:flutter_restaurant/features/home/enums/product_group_enum.dart';
import 'package:flutter_restaurant/features/home/enums/quantity_position_enum.dart';
import 'package:flutter_restaurant/features/home/widgets/product_card_widget.dart';
import 'package:flutter_restaurant/features/search/providers/search_provider.dart';
import 'package:flutter_restaurant/features/search/widget/filter_widget.dart';
import 'package:flutter_restaurant/features/search/widget/food_filter_button_widget.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/main.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SearchResultScreen extends StatefulWidget {
  final String? searchString;
  const SearchResultScreen({super.key, required this.searchString});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  String _type = 'all';

  @override
  void initState() {
    super.initState();

    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final SearchProvider searchProvider = Provider.of<SearchProvider>(context, listen: false);

    searchProvider.resetFilterData(isUpdate: false);

    int atamp = 0;
    if (atamp == 0) {
      _searchController.text = widget.searchString!.replaceAll('-', ' ');
      atamp = 1;
    }

    if(categoryProvider.categoryList == null) {
      categoryProvider.getCategoryList(true);
    }
    searchProvider.getCuisineList();

    searchProvider.saveSearchAddress(_searchController.text);
    searchProvider.searchProduct(offset: 1, name: _searchController.text, context: context, isUpdate: false);
  }

  @override
  void dispose() {
    super.dispose();

    Provider.of<SearchProvider>(Get.context!, listen: false).resetFilterData(isUpdate: false);


  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      appBar: PreferredSize(preferredSize: const Size.fromHeight(100), child: isDesktop ?  const WebAppBarWidget() :
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 5, spreadRadius: 1)],
        ),
        padding: const EdgeInsets.only(
          top: Dimensions.paddingSizeExtraLarge + Dimensions.paddingSizeDefault,
          bottom: Dimensions.paddingSizeDefault,
          right: Dimensions.paddingSizeLarge,
          left: Dimensions.paddingSizeSmall,
        ),
        child: Row(children: [

          IconButton(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(Icons.arrow_back_ios),
          ),

          Consumer<SearchProvider>(
              builder: (context, searchProvider, _) {
                return Expanded(child: CustomTextFieldWidget(
                  hintText: getTranslated('search_items_here', context),
                  isShowBorder: true,
                  isShowSuffixIcon: true,
                  suffixIconUrl: Images.closeSvg,
                  suffixIconColor: null,
                  controller: _searchController,
                  inputAction: TextInputAction.search,
                  isIcon: true,
                  onSubmit: (value){
                    searchProvider.saveSearchAddress(value);
                    searchProvider.searchProduct(offset: 1, name: value, context: context);
                  },

                  onSuffixTap: () {
                    _searchController.clear();
                  },
                ));
              }
          ),

          const SearchFilterButtonWidget(),

        ]),
      )),
      body: CustomScrollView(controller: scrollController, slivers: [

        SliverToBoxAdapter(child: Center(child: SizedBox(
          width: Dimensions.webScreenWidth,
          child: Consumer<SearchProvider>(
            builder: (context, searchProvider, child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              /// for search bar
              if(!isDesktop)

              const SizedBox(height: Dimensions.paddingSizeDefault),


              Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                  searchProvider.searchProductModel != null ? Center(
                    child: Container(
                      width: Dimensions.webScreenWidth, padding: EdgeInsets.only(
                      top: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : 0,
                      bottom: Dimensions.paddingSizeDefault,
                    ),
                      child: Row(children: [

                        Expanded(child: _searchController.text.trim().isEmpty ? const SizedBox() : RichText(softWrap: true, text: TextSpan(text: '', children: <TextSpan>[
                          TextSpan(
                            text: '${searchProvider.searchProductModel?.products?.length} ',
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                          ),
                          TextSpan(
                            text: '${getTranslated('results_for', context)} ',
                            style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                          ),
                          TextSpan(text: '" ${_searchController.text} "', style: rubikSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).textTheme.bodyMedium!.color,
                          )),
                        ]))),
                        const SizedBox(width: Dimensions.paddingSizeDefault),

                        IgnorePointer(
                          ignoring: searchProvider.searchProductModel == null,
                          child: FoodFilterButtonWidget(
                            type: _type,
                            items: productProvider.productTypeList,
                            isBorder: true,
                            onSelected: (selected) {
                              _type = selected;
                              searchProvider.searchProduct(name: _searchController.text, productType: _type, isUpdate: true, offset: 1, context: context);
                            },
                          ),
                        ),

                        if(isDesktop) const SizedBox(width: Dimensions.paddingSizeDefault),
                        if(isDesktop) const SearchFilterButtonWidget(),

                      ]),
                    ),
                  ) : const SizedBox.shrink(),

                  searchProvider.searchProductModel == null ? GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: Dimensions.paddingSizeSmall, mainAxisSpacing: Dimensions.paddingSizeSmall,
                      crossAxisCount: ResponsiveHelper.isDesktop(context) ? 5 : ResponsiveHelper.isTab(context) ? 4 : 2,
                      mainAxisExtent: !ResponsiveHelper.isDesktop(context) ? 240 : 250,
                    ),
                    itemCount: 12,
                    itemBuilder: (BuildContext context, int index) {
                      return const ProductShimmerWidget(isEnabled: true, width: double.minPositive, isList: false);
                    },
                    padding: EdgeInsets.zero,
                  ) :
                  (searchProvider.searchProductModel?.products?.isNotEmpty ?? false) ?  Padding(
                    padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                    child: PaginatedListWidget(
                      scrollController: scrollController,
                      onPaginate: (int? offset){
                        searchProvider.searchProduct(name: _searchController.text, offset: offset ?? 1, context: context, productType: _type);
                      },
                      totalSize: searchProvider.searchProductModel?.totalSize,
                      offset: searchProvider.searchProductModel?.offset,
                      builder: (_)=> GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisSpacing: Dimensions.paddingSizeSmall, mainAxisSpacing: Dimensions.paddingSizeSmall,
                          crossAxisCount: ResponsiveHelper.isDesktop(context) ? 5 :  ResponsiveHelper.isTab(context) ? 4 : 2,
                          mainAxisExtent: ResponsiveHelper.isMobile() ? 260 :  300,
                        ),
                        itemCount: searchProvider.searchProductModel?.products?.length,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) => ProductCardWidget(
                          product: searchProvider.searchProductModel!.products![index],
                          quantityPosition: ResponsiveHelper.isDesktop(context)
                              ? QuantityPosition.center : QuantityPosition.left,
                          productGroup: ProductGroup.common,
                          isShowBorder: true,
                          imageHeight: !ResponsiveHelper.isMobile() ? 200 : 160,
                          imageWidth: MediaQuery.sizeOf(context).width,
                        ),
                      ),
                    ),
                  ) : const Center(child: NoDataWidget(isFooter: false)),





                ]),
              ),





            ]),
          ),
        ))),



        if(ResponsiveHelper.isDesktop(context)) const SliverFillRemaining(
          hasScrollBody: false,
          child: FooterWidget(),
        ),

        ],
      ),
    );
  }
}

class SearchFilterButtonWidget extends StatelessWidget {
  const SearchFilterButtonWidget({
    super.key,
  });


  @override
  Widget build(BuildContext context) {


    return Padding(padding: const EdgeInsets.only(left: Dimensions.paddingSizeDefault), child: InkWell(
      onTap: () {
        List<double?> prices = [];
        prices.sort();
        double? maxValue = prices.isNotEmpty ? prices[prices.length-1] : 1000;

        ResponsiveHelper.showDialogOrBottomSheet(context, CustomAlertDialogWidget(
          height: ResponsiveHelper.isDesktop(context) ? 600 : null,
          isPadding: false, child: FilterWidget(maxValue: maxValue),
        ));


      },
      child: CustomAssetImageWidget(Images.filterSvg, width: 25, height: 25, color: Theme.of(context).primaryColor),
    ));
  }
}
