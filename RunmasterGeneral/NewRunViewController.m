//
//  NewRunViewController.m
//  RunMaster
//
//  Created by Matt Luedke on 5/19/14.
//  Copyright (c) 2014 Matt Luedke. All rights reserved.
//

#import "NewRunViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MathController.h"

@interface NewRunViewController () <UIActionSheetDelegate, CLLocationManagerDelegate>

@property BOOL soundsOn;
@property int seconds;
@property float distance;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) NSMutableArray *locations;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, weak) IBOutlet UILabel *promptLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *distTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *speedTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) IBOutlet UILabel *distLabel;
@property (nonatomic, weak) IBOutlet UILabel *speedLabel;
@property (nonatomic, weak) IBOutlet UIButton *startButton;
@property (nonatomic, weak) IBOutlet UIButton *stopButton;
@property (nonatomic, weak) IBOutlet UIButton *soundButton;

@end

@implementation NewRunViewController

-(IBAction)startPressed:(id)sender {
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Location Services Not On!"
                                  message:@"Please turn on Location Services for this app in Settings."
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    // hide the start UI
    self.startButton.hidden = YES;
    self.promptLabel.hidden = YES;
    
    // show the running stuff
    self.timeLabel.hidden = NO;
    self.timeTitleLabel.hidden = NO;
    self.distLabel.hidden = NO;
    self.distTitleLabel.hidden = NO;
    self.speedLabel.hidden = NO;
    self.speedTitleLabel.hidden = NO;
    self.stopButton.hidden = NO;
    
    self.seconds = 0;
    
    // initialize the timer
	self.timer = [NSTimer scheduledTimerWithTimeInterval:(1.0) target:self selector:@selector(eachSecond) userInfo:nil repeats:YES];
    
    self.distance = 0;
    self.locations = [NSMutableArray array];
    
    [self startLocationUpdates];
}

- (void)startLocationUpdates {
    
    // Create the location manager if this object does not
    // already have one.
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
    }
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.activityType = CLActivityTypeFitness;
    
    // Movement threshold for new events.
    self.locationManager.distanceFilter = 10; // meters
    
    [self.locationManager startUpdatingLocation];
}

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    
    CLLocation *newLocation = [locations lastObject];
    
    NSDate *eventDate = newLocation.timestamp;
    
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    
    if (abs(howRecent) < 10.0 && newLocation.horizontalAccuracy < 50) {
        
        // update distance
        if (self.locations.count > 0) {
            self.distance += [newLocation distanceFromLocation:self.locations.lastObject];
        }
        
        [self.locations addObject:newLocation];
    }
}

- (IBAction)stopPressed:(id)sender {
    
    // switch UI mode
}

- (void)saveRun
{
//    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Run" inManagedObjectContext:self.managedObjectContext];
//    
//    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
//    
//    NSMutableSet *locationSet = [NSMutableSet set];
//    for (int i = 0; i < 10; i++) {
//        NSManagedObject *locationObject = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:self.managedObjectContext];
//        
//        [locationObject setValue:[NSDate date] forKey:@"timeStamp"];
//        [locationObject setValue:[NSNumber numberWithDouble:-11.3152345] forKey:@"latitude"];
//        [locationObject setValue:[NSNumber numberWithDouble:-27.098057] forKey:@"longitude"];
//        [locationSet addObject:locationObject];
//    }
//    [newManagedObject setValue:locationSet forKey:@"locations"];
//    
//    // Save the context.
//    NSError *error = nil;
//    if (![self.managedObjectContext save:&error]) {
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
}

- (void)eachSecond {
    
    self.seconds++;
    
    if (self.seconds/3600 > 0) {
        self.timeLabel.text = [NSString stringWithFormat:@"%02i:%02i:%02i", (self.seconds/3600), ((self.seconds%3600)/60), ((self.seconds%3600)%60)];
    } else {
        self.timeLabel.text = [NSString stringWithFormat:@"%02i:%02i", (self.seconds/60), (self.seconds%60)];
    }
    
    [self updateDistAndSpeedLabels];
    [self maybePlaySound];
}

- (void)updateDistAndSpeedLabels {
    self.distLabel.font = [UIFont fontWithName:@"GillSans-Bold" size:22.0];
    self.distLabel.text = [[MathController defaultController] stringifyDistance:self.distance];
    
    self.speedLabel.text = [[MathController defaultController] stringifyAvgPaceFromDist:self.distance overTime:self.seconds];
    self.speedLabel.font = [UIFont fontWithName:@"GillSans-Bold" size:22.0];
    
    self.speedTitleLabel.text = @"Pace:";
}

- (void) maybePlaySound {
    
    // TODO: checkpoint logic
    
    if (self.soundsOn) {
        [self playSuccessSound];
    }
}

- (void)playSuccessSound {
    //Get the filename of the sound file:
    NSString *path = [NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] resourcePath], @"/genericsuccess.wav"];
    
    //declare a system sound
    SystemSoundID soundID;
    
    //Get a URL for the sound file
    NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
    
    //Use audio sevices to create the sound
    AudioServicesCreateSystemSoundID((CFURLRef)CFBridgingRetain(filePath), &soundID);
    //Use audio services to play the sound
    AudioServicesPlaySystemSound(soundID);
    
    //also vibrate
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
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
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end