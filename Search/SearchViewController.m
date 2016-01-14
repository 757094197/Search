//
//  SearchViewController.m
//  Search
//
//  Created by 薛焱 on 16/1/12.
//  Copyright © 2016年 薛焱. All rights reserved.
//

#import "SearchViewController.h"
#import <PinYin4Objc.h>

@interface SearchViewController ()<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UITableView *cityTableView;
@property (nonatomic, strong) NSMutableDictionary *dataDict;
@property (nonatomic, strong) NSMutableDictionary *dataSource;
@property (nonatomic, strong) NSMutableArray *perfixArray;
@property (nonatomic, strong) NSMutableArray *perfixSource;
@end

@implementation SearchViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.perfixArray = [NSMutableArray array];
    self.perfixSource = [NSMutableArray array];
    self.dataDict = [NSMutableDictionary dictionary];
    self.dataSource = [NSMutableDictionary dictionary];
    
    self.cityTableView.sectionIndexColor = UIColorFromRGB(0x0f2ee8);
    self.cityTableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.searchTextField.delegate = self;
    [self.searchTextField becomeFirstResponder];
    [self readDataFromLocal];
    // Do any additional setup after loading the view.
}

- (void)readDataFromLocal{
    NSString *path = [[NSBundle mainBundle]pathForResource:@"Area" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc]initWithContentsOfFile:path];
    NSMutableArray *dataArray = [NSMutableArray array];
    for (NSString *key in dict) {
        for (NSString *province in dict[key]) {
            for (NSString *cityKey in dict[key][province]) {
                NSDictionary *cityDict = dict[key][province];
                for (NSString *cityName in cityDict[cityKey]) {
                    
                    NSString *cityNameEN = [self changeEnglishToChinese:cityName withSeparator:@""];
                    NSString *perfix = [[cityNameEN substringToIndex:1] uppercaseString];
                    if (![self.perfixArray containsObject:perfix]) {
                        [self.perfixArray addObject:perfix];
                    }
                    [dataArray addObject:cityName];
                }
            }
        }
    }
    for (NSString *perfix in self.perfixArray) {
        NSMutableArray *cityArray = [NSMutableArray array];
        for (NSString *cityName in dataArray) {
            NSString *cityNameEN = [self changeEnglishToChinese:cityName withSeparator:@""];
            if ([cityNameEN hasPrefix:[perfix lowercaseString]]) {
                [cityArray addObject:cityName];
            }
        }
        [self.dataDict setObject:cityArray forKey:perfix ];
    }
    
    self.perfixArray = [NSMutableArray arrayWithArray:[self.perfixArray sortedArrayUsingSelector:@selector(compare:)]];
    self.dataSource = self.dataDict;
    self.perfixSource = self.perfixArray;
}


- (IBAction)cancleButtonAction:(UIButton *)sender {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.perfixArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.dataDict[self.perfixArray[section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchCell" forIndexPath:indexPath];
    cell.textLabel.text = self.dataDict[self.perfixArray[indexPath.section]][indexPath.row];
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *sectionView = [[UIView alloc]init];
    UILabel *indexLabel = [[UILabel alloc]initWithFrame:CGRectMake(15, 0, [UIScreen mainScreen].bounds.size.width, 23.5)];
    sectionView.backgroundColor = UIColorFromRGB(0xf8f8f8);
    indexLabel.text = self.perfixArray[section];
    [sectionView addSubview:indexLabel];
    return sectionView;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.perfixArray;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 38;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 23.5;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:self.searchTextField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UITextFieldTextDidChangeNotification object:self.searchTextField];
}

- (void)textFieldDidChange:(NSNotification *)note{
    if (self.searchTextField.text.length > 0) {
        self.dataDict = [NSMutableDictionary dictionary];
        self.perfixArray = [NSMutableArray array];
        for (NSString *perfix in self.dataSource) {
            NSMutableArray *mArray = [NSMutableArray array];
            NSString *index;
            for (NSString *cityName in self.dataSource[perfix]) {
                
                NSString *cityNameEN =[self changeEnglishToChinese:cityName withSeparator:@""];
                NSString *cityNameEN1 = [self changeEnglishToChinese:cityName withSeparator:@"!"];
                NSArray *perfixArray = [cityNameEN1 componentsSeparatedByString:@"!"];
                NSMutableString *perfixString = [NSMutableString string];
                for (NSString *str in perfixArray) {
                    
                    [perfixString appendString:[str substringToIndex:1]];
                }
                
                NSString *searchTextEN = [self changeEnglishToChinese:self.searchTextField.text withSeparator:@""];
                if ([cityNameEN hasPrefix:searchTextEN] || [perfixString hasPrefix:searchTextEN]) {
                    
                    index = [[cityNameEN substringToIndex:1] uppercaseString];
                    
                    [mArray addObject:cityName];
                }
            }
            if (index != nil) {
                [self.perfixArray addObject:index];
                [self.dataDict setObject:mArray forKey:index];
            }
        }
    }else{
        self.dataDict = self.dataSource;
        self.perfixArray = self.perfixSource;
    }
    [self.cityTableView reloadData];
}

- (NSString *)changeEnglishToChinese:(NSString *)cityName withSeparator:(NSString *)separator{
    HanyuPinyinOutputFormat *outputFormat=[[HanyuPinyinOutputFormat alloc] init];
    [outputFormat setToneType:ToneTypeWithoutTone];
    [outputFormat setVCharType:VCharTypeWithV];
    [outputFormat setCaseType:CaseTypeLowercase];
    NSString *cityNameEN =[PinyinHelper toHanyuPinyinStringWithNSString:cityName withHanyuPinyinOutputFormat:outputFormat withNSString:separator];
    return cityNameEN;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
