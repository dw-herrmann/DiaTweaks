#import "StdPatch/StdPatch.h"
#import "Updates/Updates.h"

// Dia ships nested tab groups behind the feature flag below, switched off. Dia reads flag overrides from this setting as it
// starts, so the override only takes hold on the next launch. Other overrides already set for this launch are left alone.
static NSString *const DPOverridesKey = @"transientFeatureFlagOverrides";
static NSString *const DPNestedGroupsFlag = @"nested-groups-enabled=true";

static BOOL gLoadedOn;

extern DPPatch DPNestedTabGroups;

static void DPInstallNestedTabGroups(void) {
    gLoadedOn = DPNestedTabGroups.on;
    if (!gLoadedOn) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSMutableDictionary *arguments = [[defaults volatileDomainForName:NSArgumentDomain] mutableCopy] ?: [NSMutableDictionary dictionary];
    if (arguments[DPOverridesKey]) return;
    arguments[DPOverridesKey] = DPNestedGroupsFlag;
    [defaults setVolatileDomain:arguments forName:NSArgumentDomain];
}

static void DPApplyNestedTabGroups(DPPatch *patch) {
    if (patch->on == gLoadedOn || patch->on != DPSavedOn(patch)) return;  // the self-test flips patches without saving
    NSAlert *alert = [NSAlert new];
    alert.messageText = patch->on ? @"Relaunch Dia to nest tab groups" : @"Relaunch Dia to stop nesting tab groups";
    alert.informativeText = patch->on ? @"Until then, groups can't be dragged into each other." : @"Groups you've nested stay as they are, but Dia may show them flat.";
    [alert addButtonWithTitle:@"Relaunch"];
    [alert addButtonWithTitle:@"Later"];
    if ([alert runModal] == NSAlertFirstButtonReturn) DPHandOffAndQuit(@[ @"apply" ]);
}

// There is nothing to see in Dia's views, so this only checks that the override is still there once Dia started with it.
static NSString *DPVerifyNestedTabGroups(DPPatch *patch) {
    if (!gLoadedOn) return nil;
    NSString *overrides = [NSUserDefaults.standardUserDefaults stringForKey:DPOverridesKey];
    return [overrides containsString:@"nested-groups-enabled"] ? nil : @"Dia dropped the nested groups override";
}

DP_PATCH(DPNestedTabGroups) {
    .key = @"nestedTabGroups",
    .order = 106,
    .title = @"Nested Tab Groups",
    .detail = @"Put tab groups inside other tab groups, like folders in Arc. Drag a group onto another, or choose New Group in a group's menu. Turns on a feature Dia has built but not released. Experimental.",
    .symbol = @"folder.fill.badge.plus",
    .tint = @"systemPinkColor",
    .section = @"Tabs",
    .classes = DPClasses(DPDiaTabListLayout, DPDiaTabGroupCell),
    .install = DPInstallNestedTabGroups,
    .apply = DPApplyNestedTabGroups,
    .verify = DPVerifyNestedTabGroups,
};
