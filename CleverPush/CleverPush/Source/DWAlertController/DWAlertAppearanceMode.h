#ifndef DWAlertAppearanceMode_h
#define DWAlertAppearanceMode_h

#pragma mark - Enumeration of appearance
typedef NS_ENUM (NSInteger, DWAlertAppearanceMode) {
    /// Follows Dark Mode setting on iOS 13, uses the light appearance mode on iOS 12 or lower
    DWAlertAppearanceModeAutomatic,
    /// The light appearance mode
    DWAlertAppearanceModeLight,
    /// The dark appearance mode
    DWAlertAppearanceModeDark,
};

#endif /* DWAlertAppearanceMode_h */
