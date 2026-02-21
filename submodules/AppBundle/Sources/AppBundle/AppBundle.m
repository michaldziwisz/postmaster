#import <AppBundle/AppBundle.h>

NSBundle * _Nonnull getAppBundle() {
    static NSBundle *appBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        
        NSString *pathExtension = [[bundle.bundleURL pathExtension] lowercaseString];
        if ([pathExtension isEqualToString:@"xctest"]) {
            NSURL *hostAppUrl = [[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent];
            NSBundle *hostAppBundle = [NSBundle bundleWithURL:hostAppUrl];
            if (hostAppBundle != nil) {
                bundle = hostAppBundle;
            }
        }
        if ([[bundle.bundleURL pathExtension] isEqualToString:@"appex"]) {
            bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
        } else if ([[bundle.bundleURL pathExtension] isEqualToString:@"framework"]) {
            bundle = [NSBundle bundleWithURL:[[bundle.bundleURL URLByDeletingLastPathComponent] URLByDeletingLastPathComponent]];
        } else if ([[bundle.bundleURL pathExtension] isEqualToString:@"Frameworks"]) {
            bundle = [NSBundle bundleWithURL:[bundle.bundleURL URLByDeletingLastPathComponent]];
        }
        
        if ([bundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:@"en"] == nil) {
            NSURL *parentUrl = [bundle.bundleURL URLByDeletingLastPathComponent];
            NSArray<NSURL *> *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:parentUrl includingPropertiesForKeys:nil options:0 error:nil];
            for (NSURL *entryUrl in entries) {
                if (![[[entryUrl pathExtension] lowercaseString] isEqualToString:@"app"]) {
                    continue;
                }
                NSBundle *candidateBundle = [NSBundle bundleWithURL:entryUrl];
                if (candidateBundle == nil) {
                    continue;
                }
                if ([candidateBundle pathForResource:@"Localizable" ofType:@"strings" inDirectory:nil forLocalization:@"en"] != nil) {
                    bundle = candidateBundle;
                    break;
                }
            }
        }
        appBundle = bundle;
    });
    
    return appBundle;
}

@implementation UIImage (AppBundle)

- (instancetype _Nullable)initWithBundleImageName:(NSString * _Nonnull)bundleImageName {
    return [UIImage imageNamed:bundleImageName inBundle:getAppBundle() compatibleWithTraitCollection:nil];
}

@end
