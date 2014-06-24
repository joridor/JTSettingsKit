//
//  SettingsGroup.h
//  JTSettingsEditor
//
//  Created by Joris Timmerman on 20/02/14.
//  Copyright (c) 2014 Joris Timmerman. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

enum  {
	JTSettingsOptionTypeUnknown = 0,
	JTSettingsOptionTypeSwitch = 1,
	JTSettingsOptionTypeMultiValue = 2
};
typedef NSUInteger SettingsOptionType;

@interface JTSettingsGroup : NSObject

@property NSString *title;
@property NSString *footer;

- (NSUInteger)count;

- (id)initWithTitle:(NSString *)title;
- (void)addOptionForType:(SettingsOptionType)settingType label:(NSString *)label forUserDefaultsKey:(NSString *)userDefaultsKey withValue:(id)value options:(NSDictionary *)optionsOrNil;

- (id)settingValueForSettingWithKey:(NSString *)key;
- (NSString *)settingLabelForSettingWithKey:(NSString *)key;
- (SettingsOptionType)settingTypeForSettingWithKey:(NSString *)key;

- (void)updateSettingValue:(id)value forSettingWithKey:(NSString *)key;
- (void)updateSettingLabel:(NSString *)label forSettingWithKey:(NSString *)key;
- (void)updateSettingType:(SettingsOptionType)type forSettingWithKey:(NSString *)key;

- (NSString *)keyOfSettingAt:(NSUInteger)index;

- (BOOL)hasKey:(NSString *)key;
- (NSUInteger)indexForKey:(NSString *)key;
@end
