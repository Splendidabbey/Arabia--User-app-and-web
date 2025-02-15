import 'package:flutter/material.dart';
import 'package:flutter_restaurant/features/address/domain/models/address_model.dart';
import 'package:flutter_restaurant/features/splash/providers/splash_provider.dart';
import 'package:flutter_restaurant/helper/date_converter_helper.dart';
import 'package:flutter_restaurant/helper/responsive_helper.dart';
import 'package:flutter_restaurant/localization/language_constrants.dart';
import 'package:flutter_restaurant/features/address/providers/location_provider.dart';
import 'package:flutter_restaurant/features/order/providers/order_provider.dart';
import 'package:flutter_restaurant/features/order_track/providers/time_provider.dart';
import 'package:flutter_restaurant/utill/dimensions.dart';
import 'package:flutter_restaurant/utill/images.dart';
import 'package:flutter_restaurant/utill/order_status.dart';
import 'package:flutter_restaurant/utill/styles.dart';
import 'package:flutter_restaurant/common/widgets/custom_app_bar_widget.dart';
import 'package:flutter_restaurant/helper/custom_snackbar_helper.dart';
import 'package:flutter_restaurant/common/widgets/footer_widget.dart';
import 'package:flutter_restaurant/common/widgets/web_app_bar_widget.dart';
import 'package:flutter_restaurant/features/order_track/widgets/custom_stepper_widget.dart';
import 'package:flutter_restaurant/features/order_track/widgets/tracking_map_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/timer_widget.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String? orderID;
  final String? phoneNumber;
  const OrderTrackingScreen({super.key, this.orderID, this.phoneNumber});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {

  @override
  void initState() {
    final OrderProvider orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final TimerProvider timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final LocationProvider locationProvider = Provider.of<LocationProvider>(context, listen: false);

    if(widget.orderID != null){
      locationProvider.initAddressList();

      orderProvider.trackOrder(widget.orderID, fromTracking: true, phoneNumber: widget.phoneNumber).whenComplete(() {
        if(orderProvider.trackModel != null){
          timerProvider.getEstimateDuration(orderProvider.trackModel!, context);
          if(orderProvider.trackModel?.deliveryMan != null ){
            orderProvider.getDeliveryManData(widget.orderID);
          }
        }
      });
    }else{
      orderProvider.clearPrevData();
    }
    
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    final double height = MediaQuery.sizeOf(context).height;
    final configModel = Provider.of<SplashProvider>(context, listen: false).configModel;

    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context) ? const PreferredSize(
        preferredSize: Size.fromHeight(100), child: WebAppBarWidget(),
      ) : CustomAppBarWidget(
        title: getTranslated('track_order', context)!,
        centerTitle: false,
      ) as PreferredSizeWidget,

      body: CustomScrollView(slivers: [

        SliverToBoxAdapter(child: Container(
          margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
          constraints: BoxConstraints(minHeight: !ResponsiveHelper.isDesktop(context) && height < 600 ? height : height - 400),
          child: Consumer<OrderProvider>(builder: (context, orderProvider, _) {
            String? status;
            if(orderProvider.trackModel != null) {
              status = orderProvider.trackModel?.orderStatus;
            }
            return Container(
              margin: ResponsiveHelper.isDesktop(context) ? EdgeInsets.symmetric(horizontal: (width - Dimensions.webScreenWidth) / 2) : null,
              decoration: ResponsiveHelper.isDesktop(context) ? BoxDecoration(
                color: Theme.of(context).canvasColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                boxShadow: [BoxShadow(color: Theme.of(context).shadowColor, blurRadius: 5, spreadRadius: 1)],
              ) : null,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  child: Column(children: [

                    if(widget.orderID != null)
                    if(status == OrderStatus.pending
                          || status == OrderStatus.confirmed
                          || status == OrderStatus.cooking
                          || status == OrderStatus.processing
                          || status == OrderStatus.outForDelivery
                      ) const Column(children: [
                        SizedBox(height: Dimensions.paddingSizeDefault),
                        TimerWidget(),
                      ]),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    orderProvider.trackModel != null ? Column(children: [
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${getTranslated('your_order', context)}', style: rubikSemiBold),

                        Text(' #${orderProvider.trackModel?.id}', style: rubikSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor,
                        )),
                      ]),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Column(children: [
                        CustomStepperWidget(
                          title: getTranslated('order_placed', context),
                          isComplete: status == OrderStatus.pending
                              || status == OrderStatus.confirmed
                              || status == OrderStatus.cooking
                              || status == OrderStatus.processing
                              || status == OrderStatus.outForDelivery
                              || status == OrderStatus.delivered,
                          isActive: status == OrderStatus.pending,
                          haveTopBar: false,
                          statusImage: Images.order,
                          subTitle: orderProvider.trackModel?.createdAt != null
                              ?  '${DateConverterHelper.estimatedDate(DateConverterHelper.convertStringToDatetime(orderProvider.trackModel!.createdAt!))} ${DateConverterHelper.estimatedDate(DateConverterHelper.convertStringToDatetime(orderProvider.trackModel!.createdAt!))}' : '',
                        ),

                        CustomStepperWidget(
                          title: getTranslated('confirmed', context),
                          isComplete: status == OrderStatus.confirmed
                              || status == OrderStatus.cooking
                              || status == OrderStatus.processing
                              || status == OrderStatus.outForDelivery
                              || status == OrderStatus.delivered,
                          isActive: status == OrderStatus.confirmed,
                          statusImage: Images.done,
                        ),

                        CustomStepperWidget(
                          title: getTranslated('cooking', context),
                          isComplete: status == OrderStatus.cooking
                              || status == OrderStatus.processing
                              || status == OrderStatus.outForDelivery
                              ||status == OrderStatus.delivered,
                          isActive: status == OrderStatus.cooking,
                          statusImage: Images.cooking,
                        ),

                        CustomStepperWidget(
                          title: getTranslated('preparing_for_delivery', context),
                          isComplete: status == OrderStatus.processing
                              || status == OrderStatus.outForDelivery
                              ||status == OrderStatus.delivered,
                          statusImage: Images.preparing,
                          isActive: status == OrderStatus.processing,
                          subTitle: getTranslated('your_delivery_man_is_coming', context),
                        ),

                        Consumer<LocationProvider>(builder: (context, locationProvider, _) {
                          AddressModel? address;
                          if(locationProvider.addressList != null){
                            for(int i = 0 ; i< locationProvider.addressList!.length; i++) {
                              if(locationProvider.addressList![i].id == orderProvider.trackModel!.deliveryAddressId) {
                                address = locationProvider.addressList![i];
                              }
                            }
                          }
                          return CustomStepperWidget(
                            title: getTranslated('order_is_on_the_way', context),
                            isComplete: status == OrderStatus.outForDelivery || status == OrderStatus.delivered,
                            statusImage: Images.outForDelivery,
                            height: configModel?.googleMapStatus == 0 ||  orderProvider.trackModel?.deliveryMan == null ? 30 : 130,
                            isActive: status == OrderStatus.outForDelivery,
                            trailing: orderProvider.trackModel?.deliveryMan?.phone != null ? InkWell(
                              onTap: () async {
                                Uri uri = Uri.parse('tel:${orderProvider.trackModel?.deliveryMan?.phone}');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  if(context.mounted){
                                    showCustomSnackBarHelper(getTranslated('phone_number_not_found', context));
                                  }
                                }
                              },
                              child: const Icon(Icons.phone_in_talk),
                            ) : const SizedBox(),
                            child: orderProvider.deliveryManModel != null && configModel?.googleMapStatus == 1? TrackingMapWidget(
                              deliveryManModel: orderProvider.deliveryManModel,
                              orderID: '${orderProvider.trackModel?.id}',
                              addressModel: address,
                            ) : const SizedBox.shrink(),
                          );
                        }),


                        CustomStepperWidget(
                          title: getTranslated('order_delivered', context),
                          isComplete: status == OrderStatus.delivered,
                          isActive: status == OrderStatus.delivered,
                          statusImage: Images.done,
                        ),

                      ]),
                    ]) : widget.orderID == null ?  Column(children: [
                      const SizedBox(height: Dimensions.paddingSizeLarge),
                      Image.asset(Images.outForDelivery, color: Theme.of(context).disabledColor.withOpacity(0.5), width:  70),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      Text(getTranslated('enter_your_order_id', context)!, style: rubikRegular.copyWith(
                        color: Theme.of(context).disabledColor,
                      ), maxLines: 2,  textAlign: TextAlign.center),
                      const SizedBox(height: 100),

                    ]) : const Center(child: Padding(
                      padding: EdgeInsets.all(50.0),
                      child: CircularProgressIndicator(),
                    )),
                  ]),
                ),

              ]),
            );
          }),
        )),

        if(ResponsiveHelper.isDesktop(context)) const SliverToBoxAdapter(
          // hasScrollBody: false,
          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            SizedBox(height: Dimensions.paddingSizeLarge),

            FooterWidget(),
          ]),
        ),
      ]),

    );
  }


}