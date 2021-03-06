//
//  JTSettingsContainerViewController.m
//  JTSettingsKit
//
//  Created by Joris Timmerman on 25/06/14.
//  Copyright (c) 2014 Joris Timmerman. All rights reserved.
//

#import "JTSettingsViewController.h"
#import "JTSettingsTableViewController.h"
#import "JTSettingsCustomEditorBaseViewController.h"
#import "JTSettingsWebViewViewController.h"
#import "JTSettingsCell.h"

@interface JTSettingsViewController ()<JTSettingsVisualizerDelegate, JTSettingsEditorDelegate> {
  NSMutableArray *_settingGroups;
  UIViewController<JTSettingsVisualizing> *settingsController;
}

@end

@implementation JTSettingsViewController

- (id)initWithSettingsVisualizerClass:(Class)settingsViewControllerClass {
  self = [super init];
  if (self) {
    if (![settingsViewControllerClass conformsToProtocol:@protocol(JTSettingsVisualizing)] ||
        ![settingsViewControllerClass isSubclassOfClass:[UIViewController class]]) {
      [NSException raise:@"Invalid class."
                  format:@"Invalid class passed to init function, given class %@ is not a %@ "
                         @"and/or does not implement the protocol %@",
                         NSStringFromClass(settingsViewControllerClass),
                         NSStringFromClass([UIViewController class]),
                         NSStringFromProtocol(@protocol(JTSettingsVisualizing))];
    }

    settingsController =
        (UIViewController<JTSettingsVisualizing> *)[[settingsViewControllerClass alloc] init];
    settingsController.delegate = self;
    _autoStoreValuesInUserDefaults = NO;

    [self addChildViewController:settingsController];
  }
  return self;
}

- (id)init {
  self = [self initWithSettingsVisualizerClass:[JTSettingsTableViewController class]];
  return self;
}

- (NSUInteger)numSettingsGroups {
  return [_settingGroups count];
}

- (void)setTitle:(NSString *)title forGroupAt:(NSUInteger)index {
  JTSettingsGroup *group = (JTSettingsGroup *)[_settingGroups objectAtIndex:index];
  if (group) {
    group.title = title;
  }
}

- (void)setFooter:(NSString *)footer forGroupAt:(NSUInteger)index {
  JTSettingsGroup *group = (JTSettingsGroup *)[_settingGroups objectAtIndex:index];
  if (group) {
    group.footer = footer;
  }
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)addSettingsGroup:(JTSettingsGroup *)group {
  [self addSettingsGroup:group at:_settingGroups.count];
}

- (void)addSettingsGroup:(JTSettingsGroup *)group at:(NSUInteger)index {
  if (!_settingGroups) {
    _settingGroups = [NSMutableArray array];
  }

  if (group.key) {
    JTSettingsGroup *grpWithKey = [self settingsGroupWithKey:group.key];
    if (grpWithKey) {
      [NSException raise:@"Duplicate key error"
                  format:@"The key %@ was already used for group with title: %@", group.key,
                         grpWithKey.title];
    }
  }

  [_settingGroups insertObject:group atIndex:index];
  [settingsController reload];
}

- (void)removeSettingsGroup:(JTSettingsGroup *)group {
  if (!_settingGroups) {
    return;
  }

  [_settingGroups removeObject:group];
  [settingsController reload];
}

- (JTSettingsGroup *)settingsGroupWithKey:(NSString *)key {
  if (!_settingGroups) {
    return nil;
  }

  for (JTSettingsGroup *group in _settingGroups) {
    if ([group.key isEqualToString:key]) {
      return group;
    }
  }

  return nil;
}

- (void)reloadSettingForKey:(NSString *)key inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *grp = [_settingGroups objectAtIndex:groupIndex];
  if (grp) {
		[self reloadSettingForKey:key inGroup:grp];
  }
}

- (void)reloadSettingForKey:(NSString *)key inGroup:(JTSettingsGroup *) grp {
	if (grp) {
		NSUInteger index = [grp indexForKey:key];
		if (index != NSNotFound) {
			[settingsController reloadItemAt:index
														 inGroupAt:[_settingGroups indexOfObject:grp]];
		}
	}
}

- (void)reload {
  [settingsController reload];
}

#pragma mark - table delegate

- (NSUInteger)numberOfGroups {
  return _settingGroups.count;
}

- (NSUInteger)numberOfSettingsInGroupAt:(NSUInteger)index {
  JTSettingsGroup *grp = [_settingGroups objectAtIndex:index];
  if (grp) {
    return [grp count];
  }
  return 0;
}

- (NSString *)titleForGroupAt:(NSUInteger)index {
  JTSettingsGroup *group = (JTSettingsGroup *)[_settingGroups objectAtIndex:index];

  if (group) {
    return [group title];
  }
  return nil;
}

- (NSString *)footerForGroupAt:(NSUInteger)index {
  JTSettingsGroup *group = (JTSettingsGroup *)[_settingGroups objectAtIndex:index];

  if (group) {
    return [group footer];
  }

  return nil;
}

- (NSString *)settingKeyForSettingAt:(NSUInteger)index inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *group = [self settingsGroupAtIndex:groupIndex];
  if (group) {
    return [group keyOfSettingAt:index];
  }
  return nil;
}

- (BOOL)settingEnabledForSettingWithKey:(NSString *)key inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *group = [self settingsGroupAtIndex:groupIndex];
  if (group) {
    return [group settingWithKeyIsEnabled:key];
  }
  return NO;
}

- (BOOL)shouldSelectSettingWithKey:(NSString *)key inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *group = [self settingsGroupAtIndex:groupIndex];
  if (group) {
    return [group hasEditorForSettingWithKey:key];
  }
  return NO;
}

- (UIViewController<JTSettingsEditing> *)editorForSettingWithKey:(NSString *)key
                                                       inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *group = (JTSettingsGroup *)[_settingGroups objectAtIndex:groupIndex];

  if (group) {
    UIViewController<JTSettingsEditing> *editor;
    JTSettingType type = [group settingTypeForSettingWithKey:key];
    if (type == JTSettingTypeLinkedView) {
      UIView *view = (UIView *) [group settingValueForSettingWithKey:key];
      
      if (!view) {
        return nil;
      }
      
      editor = [[JTSettingsCustomEditorBaseViewController alloc] init];
      editor.view = view;
    } else if(type==JTSettingTypeWebView){
      NSURL *url  = (NSURL *) [group settingValueForSettingWithKey:key];
      if(!url) {
        return nil;
      }
		
      editor = [[JTSettingsWebViewViewController alloc] init];
    } else {
      Class editorClass = [group editorClassForSettingWithKey:key];

      if (!editorClass) {
        return nil;
      }

      editor = [[editorClass alloc] init];
    }
    
      editor.title = [group settingLabelForSettingWithKey:key];
      editor.settingsGroup = group;
      editor.settingsKey = key;

      NSDictionary *editorData = nil;
      if ([self.settingDelegate respondsToSelector:@selector(settingsViewController:
                                                       dataForSettingEditorDataForSettingKey:inGroup:)]) {
        editorData = [self.settingDelegate settingsViewController:self
                            dataForSettingEditorDataForSettingKey:key inGroup:group];
      }
      editor.data = editorData;
      editor.selectedValue =
          [NSString stringWithFormat:@"%@", [group settingValueForSettingWithKey:key]];

      editor.delegate = self;

      NSDictionary *editorOptions = [group editorPropertiesForSettingWithKey:key];
      if (editorOptions) {
        for (NSString *key in [editorOptions allKeys]) {
          [editor setValue:[editorOptions valueForKey:key] forKey:key];
        }
      }

      return editor;
  }

  return nil;
}

- (NSString *)settingLabelForSettingWithKey:(NSString *)key inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *group = [_settingGroups objectAtIndex:groupIndex];
  if (group) {
    return [group settingLabelForSettingWithKey:key];
  }
  return nil;
}

- (JTSettingType)settingTypeForSettingWithKey:(NSString *)key inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *group = [_settingGroups objectAtIndex:groupIndex];
  if (group) {
    return [group settingTypeForSettingWithKey:key];
  }
  return JTSettingTypeCustomCell;
}

- (id)selectedDataForSettingWithKey:(NSString *)key inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *group = [_settingGroups objectAtIndex:groupIndex];
  if (group) {
    return [group settingValueForSettingWithKey:key];
  }
  return nil;
}

- (NSString *)selectedDataDescriptionForSettingWithKey:(NSString *)key
                                             inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *group = [_settingGroups objectAtIndex:groupIndex];
  if (group) {
    id value = [group settingValueForSettingWithKey:key];
    if ([self.settingDelegate respondsToSelector:@selector(descriptionForValue:forKey:inGroup:)]) {
      return [self.settingDelegate descriptionForValue:value forKey:key inGroup:group];
    }
  }
  return nil;
}

- (JTSettingsGroup *)settingsGroupAtIndex:(NSUInteger)groupIndex {
  return (JTSettingsGroup *)[_settingGroups objectAtIndex:groupIndex];
}

- (void)valueChangedForSettingWithKey:(NSString *)key
                              toValue:(id)value
                            inGroupAt:(NSUInteger)groupIndex {
  JTSettingsGroup *group = [self settingsGroupAtIndex:groupIndex];
  [self updateSettingWithKey:key inGroup:group toValue:value];
}

#pragma mark - SettingsOptionsViewControllerDelegate
- (void)settingsEditorViewController:(UIViewController<JTSettingsEditing> *)viewController
         selectedValueChangedToValue:(id)value {
  [self updateSettingWithKey:viewController.settingsKey
                     inGroup:viewController.settingsGroup
                     toValue:value];
}

- (void)updateSettingWithKey:(NSString *)key inGroup:(JTSettingsGroup *)group toValue:(id)value {
  [group updateSettingValue:value forSettingWithKey:key];

  if (self.autoStoreValuesInUserDefaults) {
    JTSettingType settingType = [group settingTypeForSettingWithKey:key];
    switch (settingType) {
      case JTSettingTypeSwitch:
        [[NSUserDefaults standardUserDefaults] setBool:[(NSNumber *)value boolValue] forKey:key];
        break;

      default:
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
        break;
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
  }

  NSUInteger cellIndex = [group indexForKey:key];
  NSUInteger groupIndex = [_settingGroups indexOfObject:group];
  if (cellIndex != NSNotFound && groupIndex != NSNotFound) {
    [settingsController reloadItemAt:cellIndex inGroupAt:groupIndex];
  }

  if ([self.settingDelegate respondsToSelector:@selector(settingsViewController:
                                                   valueChangedForSettingWithKey:
                                                                         toValue:inGroup:)]) {
    [self.settingDelegate settingsViewController:self
                   valueChangedForSettingWithKey:key
                                         toValue:value
                                         inGroup:group];
  }
}

-(void) willDrawView:(UIView *)view forSettingWithKey:(NSString *)key inGroupAt:(NSUInteger)group {
  if([self.settingDelegate respondsToSelector:@selector(settingsViewController:willDrawView:forSettingWithKey:inGroup:)]){
    [self.settingDelegate settingsViewController:self
                                    willDrawView:view forSettingWithKey:key
                                         inGroup:[self settingsGroupAtIndex:group]];
  }
}

@end
