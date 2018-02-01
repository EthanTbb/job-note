//  
//  PaymentViewController.m  
//  IAPPayTest  
//  
//  Created by silicon on 14-10-28.  
//  Copyright (c) 2014年 silicon. All rights reserved.  
//  
  
#import "PaymentViewController.h" 
#import "platform/ios/CCLuaObjcBridge.h"
  
@interface PaymentViewController ()  
  
@end  
@implementation PaymentViewController  
{
    int state;
    int luaCallback;
    NSString *s_productID;
}
  
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil  
{  
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];  
    if (self) {
        // Custom initialization  
    }  
    return self;  
}  
  
- (void)viewDidLoad  
{  
    [super viewDidLoad];  
    // Do any additional setup after loading the view from its nib.
}  
  
- (void)didReceiveMemoryWarning  
{  
    [super didReceiveMemoryWarning];  
    // Dispose of any resources that can be recreated.  
}  
  
- (IBAction)purchaseFunc:(id)sender {  
}  


- (void)applicationPayRequest:(NSDictionary *) dict{
    NSLog(@"开始监听支付啦啦啦啦");
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    self->s_productID = [dict objectForKey:@"productId"];
    NSLog(@"applicationPayRequest bbbbbbbbbb %@", self->s_productID);
    self->luaCallback = [[dict objectForKey:@"callback"] intValue];
    NSLog(@"%d", self->luaCallback);
    NSLog(@"%d", [[dict objectForKey:@"callback"] intValue]);
    [self requestProductData:self->s_productID];
}
  
//请求商品  
- (void)requestProductData:(NSString *)type{  
    if([SKPaymentQueue canMakePayments]){

        NSArray *productArray = [[NSArray alloc] initWithObjects:type, nil];
        NSSet *productSet = [NSSet setWithArray:productArray];  
        SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productSet];  
        request.delegate = self;  
        [request start];  
    }else{  
        NSLog(@"不允许程序内付费");  
    }
      
}  
  
//收到产品返回信息  
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{  
  
    NSLog(@"--------------收到产品反馈消息---------------------");  
    NSArray *product = response.products;  
    if([product count] == 0){  
        NSLog(@"--------------没有商品------------------");  
        return;  
    }  
      
    NSLog(@"productID:%@", response.invalidProductIdentifiers);  
    NSLog(@"产品付费数量:%d",[product count]);  
      
    SKProduct *p = nil;  
    for (SKProduct *pro in product) {  
        NSLog(@"%@", [pro description]);  
        NSLog(@"%@", [pro localizedTitle]);  
        NSLog(@"%@", [pro localizedDescription]);  
        NSLog(@"%@", [pro price]);  
        NSLog(@"%@", [pro productIdentifier]);  
          
        if([pro.productIdentifier isEqualToString:self->s_productID]){
            p = pro;  
        }  
    }  
      
    SKPayment *payment = [SKPayment paymentWithProduct:p];  
      
    NSLog(@"发送购买请求");  
    [[SKPaymentQueue defaultQueue] addPayment:payment];  
}  
  
//请求失败  
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{  
    NSLog(@"------------------错误-----------------:%@", error);
    self->state = -1;
}  
  
- (void)requestDidFinish:(SKRequest *)request{  
    NSLog(@"------------反馈信息结束-----------------");
}  
  
  
//监听购买结果  
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transaction{

    for(SKPaymentTransaction *tran in transaction){  
          
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"交易完成");
                self->state = 1;
                [self completeTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"商品添加进列表");
                self->state = 0;
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"已经购买过商品");
                self->state = -1;
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"交易失败");
                self->state = -2;
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                [self completeTransaction:tran];
                break;
            default:
                break;
        }
    }  
}  
  
//交易结束  
- (void)completeTransaction:(SKPaymentTransaction *)transaction{
    NSLog(@"当前交易状态%d",self->state);
    cocos2d::LuaObjcBridge::pushLuaFunctionById(self->luaCallback);
    if (self->state == 1) {
        // 验证凭据，获取到苹果返回的交易凭据
        // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
        NSString *encodeStr = [receiptData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        cocos2d::LuaValueDict item;
        item["event"] = cocos2d::LuaValue::stringValue([@"SUCCEED" UTF8String]);
        item["data"] = cocos2d::LuaValue::stringValue([encodeStr UTF8String]);
        cocos2d::LuaObjcBridge::getStack()->pushLuaValueDict(item);
        cocos2d::LuaObjcBridge::getStack()->executeFunction(1);
    }else{
        cocos2d::LuaValueDict item;
        item["event"] = cocos2d::LuaValue::stringValue([@"FAILED" UTF8String]);
        item["data"] = cocos2d::LuaValue::stringValue([@"" UTF8String]);
        cocos2d::LuaObjcBridge::getStack()->pushLuaValueDict(item);
        cocos2d::LuaObjcBridge::getStack()->executeFunction(1);
    }
    cocos2d::LuaObjcBridge::releaseLuaFunctionById(self->luaCallback);
    NSLog(@"移除支付监听。。");
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}  
  
  
- (void)dealloc{
    [super dealloc];  
}  
  
@end  
