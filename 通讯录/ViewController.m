//
//  ViewController.m
//  通讯录
//
//  Created by 法大大 on 16/4/12.
//  Copyright © 2016年 fadada. All rights reserved.
//

#import "ViewController.h"

#import <AddressBookUI/AddressBookUI.h>
#import <AddressBook/AddressBook.h>

#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSArray * array = [self getAddressBookArray];
    
    
    NSLog(@"%@",array);
}

/**
 *  获取通讯录号码
 */
- (NSArray *)getAddressBookArray{

    
    __block NSMutableArray * AddressBookMutArray = [[NSMutableArray alloc]init];
    
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0f) {
        
        CNContactStore *stroe = [[CNContactStore alloc] init];
        
        
        
        CNContactFetchRequest *fetchRequest = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactGivenNameKey,CNContactNamePrefixKey,CNContactNameSuffixKey,CNContactMiddleNameKey,CNContactFamilyNameKey,CNContactPhoneNumbersKey]];
        //提取数据
        [stroe enumerateContactsWithFetchRequest:fetchRequest error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            
        
            //用户字典
            NSMutableDictionary * AddressBookDict = [[NSMutableDictionary alloc]init];
            
            //获取联系人名字
            [AddressBookDict setValue:[NSString stringWithFormat:@"%@%@%@" ,contact.familyName==nil?@"":contact.familyName,contact.middleName==nil?@"":contact.middleName,contact.givenName==nil?@"":contact.givenName] forKey:@"name"];
            
            CNLabeledValue * labelValue = [contact.phoneNumbers firstObject];
            CNPhoneNumber *phoneNumber = labelValue.value;
            
            //获取手机号
            NSString *phoneValue = phoneNumber.stringValue;
            
            //获取分组
//            NSString *phoneLabel = labelValue.label;
            
            [AddressBookDict setValue:phoneValue forKey:@"phone"];

            [AddressBookMutArray addObject:AddressBookDict];
  
        }];
        
        
        return AddressBookMutArray;
    
    }else{
    
        //这个变量用于记录授权是否成功，即用户是否允许我们访问通讯录
        int __block tip=0;
        //声明一个通讯簿的引用
    
        ABAddressBookRef addBook =nil;
        //因为在IOS6.0之后和之前的权限申请方式有所差别，这里做个判断
        if ([[UIDevice currentDevice].systemVersion floatValue]>=6.0) {
            //创建通讯簿的引用
            addBook= ABAddressBookCreateWithOptions(NULL, NULL);
            //创建一个出事信号量为0的信号
            dispatch_semaphore_t sema=dispatch_semaphore_create(0);
            //申请访问权限
            ABAddressBookRequestAccessWithCompletion(addBook, ^(bool greanted, CFErrorRef error)        {
                //greanted为YES是表示用户允许，否则为不允许
                if (!greanted) {
                    tip=1;
                }
                //发送一次信号
                dispatch_semaphore_signal(sema);
            });
            //等待信号触发
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }else{
            //IOS6之前
            addBook =ABAddressBookCreate();
        }
        
        //如果没有权限
        if (tip) {
            
            //做一个友好的提示
            UIAlertView * alart = [[UIAlertView alloc]initWithTitle:@"温馨提示" message:@"请您设置允许APP访问您的通讯录\nSettings>General>Privacy\n设置>隐私>通讯录>打开 法大大 右边的开关" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alart show];
            
            
            return nil;
            
        }else {
        
            //获取所有联系人的数组
            CFArrayRef allLinkPeople = ABAddressBookCopyArrayOfAllPeople(addBook);
            //获取联系人总数
            CFIndex number = ABAddressBookGetPersonCount(addBook);
            //进行遍历
            for (NSInteger i=0; i<number; i++) {
            
                //用户字典
                NSMutableDictionary * AddressBookDict = [[NSMutableDictionary alloc]init];
            
                //获取联系人对象的引用
                ABRecordRef  people = CFArrayGetValueAtIndex(allLinkPeople, i);
                //获取当前联系人名字
                NSString*firstName=(__bridge NSString *)(ABRecordCopyValue(people, kABPersonFirstNameProperty));
                //获取当前联系人姓氏
                NSString*lastName=(__bridge NSString *)(ABRecordCopyValue(people, kABPersonLastNameProperty));
                //获取当前联系人中间名
                NSString*middleName=(__bridge NSString*)(ABRecordCopyValue(people, kABPersonMiddleNameProperty));
                //获取当前联系人的电话 数组
                NSMutableArray * phoneArr = [[NSMutableArray alloc]init];
                ABMultiValueRef phones= ABRecordCopyValue(people, kABPersonPhoneProperty);
                for (NSInteger j=0; j<ABMultiValueGetCount(phones); j++) {
                    [phoneArr addObject:(__bridge NSString *)(ABMultiValueCopyValueAtIndex(phones, j))];
                }
            
                [AddressBookDict setValue:[NSString stringWithFormat:@"%@%@%@" ,lastName==nil?@"":lastName,middleName==nil?@"":middleName,firstName==nil?@"":firstName] forKey:@"name"];
                [AddressBookDict setValue:[phoneArr firstObject] forKey:@"phone"];
            
                [AddressBookMutArray addObject:AddressBookDict];
            }

            return AddressBookMutArray;
            
        }// end if (tip)
    }// end if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0f)


}

#pragma mark -- ABPeoplePickerNavigationControllerDelegate




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
