

#import "HPMapViewController.h"
#include <stdlib.h>

enum{
    gkMessageHandoffInfo,
    gkMessageNumHitInfo,
    gkMessageHitPhotoInfo,
    gkMessageToolbarHitInfo,
    gkMessageQuestionCardHit,
    gkMessageQuestionCardRight,
    gkMessageQuestionCardWrong
};

typedef struct
{
    int nowPressedNumberTrs;
} NumHitInfo;

typedef struct
{
    int globalPressedPositionTrs;
} HitPhotoInfo;

typedef struct
{
    int toolbarPressedTrs;
} ToolbarHitInfo;

typedef struct
{
    int questionCardSelectedNumberTrs;
} QuestionCardHitInfo;

NumHitInfo numHitInfoMessage;
HitPhotoInfo hitPhotoInfoMessage;
ToolbarHitInfo toolbarHitInfoMessage;
QuestionCardHitInfo questionCardHitInfoMessage;

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)


@interface HPMapViewController ()

@end

@implementation HPMapViewController

//button的listener
- (IBAction)buttonHit_toolbar_function:(id)sender{
    
//    NSString *hello = @"hello ipad2";
//    NSMutableData *data = [hello dataUsingEncoding:NSUTF8StringEncoding];
//    [session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
    UIButton *inputButton=(UIButton *)sender;
    NSLog(@"%d",inputButton.tag);
    
    UIButton *buttonTemp;
    
    
    NSMutableData *data = [NSMutableData dataWithCapacity:1 + sizeof(ToolbarHitInfo)];
    char messageType = gkMessageToolbarHitInfo;
    [data appendBytes:&messageType length:1];
    ToolbarHitInfo message;
    message.toolbarPressedTrs = inputButton.tag;
    [data appendBytes:&message length:sizeof(ToolbarHitInfo)];
    [self sendData:data useSession:session];
    
    
    switch (inputButton.tag) {
        case tag_button_toolbar_1_light:
            buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_1_light-tag_button_toolbar_Base-1)];
            if (self.toolbarLightOn) {
                self.toolbarLightOn=NO;
                [buttonTemp setBackgroundImage:[UIImage imageNamed:@"light_hint_off"] forState:UIControlStateNormal];
            }else{
                self.toolbarLightOn=YES;
                [buttonTemp setBackgroundImage:[UIImage imageNamed:@"light_hint_on"] forState:UIControlStateNormal];
            }
            break;
        case tag_button_toolbar_3_music:
            buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_3_music-tag_button_toolbar_Base-1)];
            if (self.toolbarMusicOn) {
                self.toolbarMusicOn=NO;
                [buttonTemp setBackgroundImage:[UIImage imageNamed:@"music_off"] forState:UIControlStateNormal];
            }else{
                self.toolbarMusicOn=YES;
                [buttonTemp setBackgroundImage:[UIImage imageNamed:@"music_press"] forState:UIControlStateNormal];
            }
            break;
        case tag_button_toolbar_0_map:
            switch (self.gameState) {
                case gameState_photoDisplay:
                    [self showPhoto:0];//把照片關掉ㄅ
                    [self playerHandoff];//換人了
                    break;
                case gameState_chanceDisplayOutside:
                    [self showChance:EXIT andTarget:UNIMPORTANT];
                    [self playerHandoff];//換人了
                    break;
                case gameState_movieDisplayPlaying:
                    [self showMoiveAndMusic:movieAndMusicState_movieStop andSelectedView:UNIMPORTANT];
                    [self playerHandoff];//換人了
                    break;
                case gameState_musicDisplayPlaying:
                    [self showMoiveAndMusic:movieAndMusicState_musicStop andSelectedView:UNIMPORTANT];
                    [self playerHandoff];//換人了
                    break;
                default:
                    break;
            }
            break;
        case tag_button_toolbar_2_play:
            switch (self.toolbarPlayerState) {
                case playerStateType_prepared:
                    if(self.movieOrMusicNow==movieOrMusic_movie){
                        //$$廣播
                        [self showMoiveAndMusic:movieAndMusicState_moviePlay andSelectedView:UNIMPORTANT];
                    }else if(self.movieOrMusicNow==movieOrMusic_music){
                        [self showMoiveAndMusic:movieAndMusicState_musicPlay andSelectedView:UNIMPORTANT];
                    }
                    buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_2_play-tag_button_toolbar_Base-1)];
                    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"play_press"] forState:UIControlStateNormal];
                    break;
                case playerStateType_play:
                    buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_2_play-tag_button_toolbar_Base-1)];
                    self.toolbarPlayerState=playerStateType_pause;
                    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"pause_press"] forState:UIControlStateNormal];
                    
                    if(self.movieOrMusicNow==movieOrMusic_movie){
                        //$$廣播
                        [moviePlayer pause];
                    }else if(self.movieOrMusicNow==movieOrMusic_music){
                        [musicPlayer pause];
                    }
                    
                    
                    break;
                case playerStateType_pause:
                    buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_2_play-tag_button_toolbar_Base-1)];
                    self.toolbarPlayerState=playerStateType_play;
                    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"play_press"] forState:UIControlStateNormal];
                    if(self.movieOrMusicNow==movieOrMusic_movie){
                        //$$廣播
                        [moviePlayer play];
                    }else if(self.movieOrMusicNow==movieOrMusic_music){
                        [musicPlayer play];
                    }
                    break;
                case playerStateType_none:
                default:
                    break;
            }
            break;
        default:
            break;
    }

    
}

- (void)buttonHit_toolbar_functionFromRemote{
    int pressedTag = toolbarHitInfoMessage.toolbarPressedTrs;
    
    switch (pressedTag) {
        case tag_button_toolbar_1_light:
            if (self.toolbarLightOn) {
                self.toolbarLightOn=NO;
            }else{
                self.toolbarLightOn=YES;
            }
            break;
        case tag_button_toolbar_3_music:
            if (self.toolbarMusicOn) {
                self.toolbarMusicOn=NO;
            }else{
                self.toolbarMusicOn=YES;
            }
            break;
        case tag_button_toolbar_0_map:
            switch (self.gameState) {
                case gameState_photoDisplay:
                    [self showPhoto:0];//把照片關掉ㄅ
                    //其中一台handoff時會送同步訊號，所以這裡不用再handoff
//                    [self playerHandoff];//換人了
                    break;
                case gameState_chanceDisplayOutside:
                    [self showChance:EXIT andTarget:UNIMPORTANT];
//                    [self playerHandoff];//換人了
                    break;
                case gameState_movieDisplayPlaying:
                    [self showMoiveAndMusic:movieAndMusicState_movieStop andSelectedView:UNIMPORTANT];
//                    [self playerHandoff];//換人了
                    break;
                case gameState_musicDisplayPlaying:
                    [self showMoiveAndMusic:movieAndMusicState_musicStop andSelectedView:UNIMPORTANT];
//                    [self playerHandoff];//換人了
                    break;
                default:
                    break;
            }
            break;
        case tag_button_toolbar_2_play:
            switch (self.toolbarPlayerState) {
                case playerStateType_prepared:
                    if(self.movieOrMusicNow==movieOrMusic_movie){
                        //$$廣播
                        [self showMoiveAndMusic:movieAndMusicState_moviePlay andSelectedView:UNIMPORTANT];
                    }else if(self.movieOrMusicNow==movieOrMusic_music){
                        [self showMoiveAndMusic:movieAndMusicState_musicPlay andSelectedView:UNIMPORTANT];
                    }
                    break;
                case playerStateType_play:
                    self.toolbarPlayerState=playerStateType_pause;
                    
                    if(self.movieOrMusicNow==movieOrMusic_movie){
                        //$$廣播
                        [moviePlayer pause];
                    }else if(self.movieOrMusicNow==movieOrMusic_music){
                        [musicPlayer pause];
                    }
                    
                    
                    break;
                case playerStateType_pause:
                    self.toolbarPlayerState=playerStateType_play;
                    if(self.movieOrMusicNow==movieOrMusic_movie){
                        //$$廣播
                        [moviePlayer play];
                    }else if(self.movieOrMusicNow==movieOrMusic_music){
                        [musicPlayer play];
                    }
                    break;
                case playerStateType_none:
                default:
                    break;
            }
            break;
        default:
            break;
    }

}
-(void) button_toolbar_number_darkener{
    int i;
    UIButton *buttonTemp;
    for(i=1;i<=6;i++){
        buttonTemp=[self.button_toolbar_number objectAtIndex:i];
        [buttonTemp setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"button_%d_dark",i]] forState:UIControlStateNormal];
    }

}
- (IBAction)buttonHit_toolbar_number:(id)sender{
    UIButton *inputButton=(UIButton *)sender;
    NSLog(@"%d",inputButton.tag);
    [self button_toolbar_number_darkener];
    int nowPressedNumber=(inputButton.tag-tag_button_toolbar_number_1+1);
    UIButton *buttonTemp;
    
    if (self.gameState==gameState_throwDice) {
        buttonTemp=[self.button_toolbar_number objectAtIndex:nowPressedNumber];
        [buttonTemp setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"button_%d_light",nowPressedNumber]] forState:UIControlStateNormal];
        //重置走x步
        self.stepToGo=nowPressedNumber;
        [self stepToGoDisplay];
        
        HPPlayer *presentPlayer=[self.playerList objectAtIndex:self.whoseTurn];
        [self resetAllIconInState:2 andFocusedPlayer:self.whoseTurn];
        
    }

    
    NSMutableData *data = [NSMutableData dataWithCapacity:1 + sizeof(NumHitInfo)];
    char messageType = gkMessageNumHitInfo;
    [data appendBytes:&messageType length:1];
    NumHitInfo message;
    message.nowPressedNumberTrs=nowPressedNumber;
    [data appendBytes:&message length:sizeof(NumHitInfo)];
    [self sendData:data useSession:session];
    
}
//根據現在掌權的使用者改變背景顏色
-(void)backgroundColorReset:(int)typeInput{
    //type:0 正常地圖的背景顏色
    //     1 播放影片音樂時，遮住後面的背景顏色
    //     2 腌仔鑣的木頭桌
    if(typeInput==0){
        switch (self.whoseTurn) {
            case playerColor_red:
                [self.backgroundColor setImage:[self.backgroundImageList objectAtIndex:playerColor_red]];
                break;
            case playerColor_yellow:
                [self.backgroundColor setImage:[self.backgroundImageList objectAtIndex:playerColor_yellow]];
                break;
    //        case playerColor_blue:
    //            [self.backgroundColor setImage:[self.backgroundImageList objectAtIndex:playerColor_red]];
    //            break;
            case playerColor_green:
                [self.backgroundColor setImage:[self.backgroundImageList objectAtIndex:playerColor_green]];
                break;
            case playerColor_orange:
                [self.backgroundColor setImage:[self.backgroundImageList objectAtIndex:playerColor_orange]];
                break;
            default:
                break;
        }
    }else if(typeInput==1){
        switch (self.whoseTurn) {
            case playerColor_red:
                [self.imageView_movie_background_color setImage:[self.backgroundImageList objectAtIndex:playerColor_red]];
                break;
            case playerColor_yellow:
                [self.imageView_movie_background_color setImage:[self.backgroundImageList objectAtIndex:playerColor_yellow]];
                break;
            case playerColor_green:
                [self.imageView_movie_background_color setImage:[self.backgroundImageList objectAtIndex:playerColor_green]];
                break;
            case playerColor_orange:
                [self.imageView_movie_background_color setImage:[self.backgroundImageList objectAtIndex:playerColor_orange]];
                break;
            default:
                break;
        }
    }else if (typeInput==2){
        [self.imageView_movie_background_color setImage:[self.backgroundImageList objectAtIndex:playerColor_ForTable]];
    }

}
//統一管控所有跟blink有關的動畫
-(void)blinkAnimationFor:(blinkAnimationType)blinkAnimationTypeInput andFocus:(NSInteger)focusedPosition andState:(blinkAnimationState)blinkAnimationStateInput{
    //足跡的blink
    HPPlayer *presentPlayer=[self.playerList objectAtIndex:self.whoseTurn];
    if(blinkAnimationTypeInput==blinkAnimationType_icon){

        CGRect blinkFrame;//要blink的位置
        switch (presentPlayer.playerPosition) {
            case 0:
                self.image_icon_blink.frame=CGRectMake(478, 800, 231, 228);
                break;
            case 1:
                self.image_icon_blink.frame=CGRectMake(470,310, 231, 228);
                break;
            case 2:
                self.image_icon_blink.frame=CGRectMake(143,198, 231, 228);
                break;
            case 3:
                self.image_icon_blink.frame=CGRectMake(529,199, 231, 228);
                break;
            case 4:
                self.image_icon_blink.frame=CGRectMake(163,223, 231, 228);
                break;
            case 5:
                self.image_icon_blink.frame=CGRectMake(55,628, 231, 228);
                break;
            case 6:
                self.image_icon_blink.frame=CGRectMake(55,68, 231, 228);
                break;
            case 7:
                self.image_icon_blink.frame=CGRectMake(65,548, 231, 228);
                break;
            case 8:
                self.image_icon_blink.frame=CGRectMake(388,688, 231, 228);
                break;
            case 9:
                self.image_icon_blink.frame=CGRectMake(2,688, 231, 228);
                break;
            case 10:
                self.image_icon_blink.frame=CGRectMake(384,633, 231, 228);
                break;
            case 11:
                self.image_icon_blink.frame=CGRectMake(479,200, 231, 228);
                break;
            default:
                break;
        }
        if(blinkAnimationStateInput==blinkAnimationState_on){
            [self.image_icon_blink startAnimating];
        }else{
            [self.image_icon_blink stopAnimating];
        }
    }else if(blinkAnimationTypeInput==blinkAnimationType_photo){
        int j;
        for(j=0;j<12;j++){//就全關吧，我也懶得算了
            [[self.image_photo_blink objectAtIndex:j] stopAnimating];
        }
        if(blinkAnimationStateInput==blinkAnimationState_on){
            if(self.gameState==gameState_moveForward){
                if(self.toolbarLightOn){//全部燈光提示都要有的
                    for(j=presentPlayer.playerPosition+1;j<=presentPlayer.playerPosition+self.stepToGo;j++){//再把要的打開
                        if(j>=(self.viewNumber*3)&&j<(self.viewNumber+1)*3){//在可視範圍中
                            [[self.image_photo_blink objectAtIndex:(j%3+self.whoseTurn*3)] startAnimating];//顏色正確的燈閃出來
                        }
                    }
                }else{//只要下一步提示的
                    if(presentPlayer.playerPosition<=(presentPlayer.playerPosition+self.stepToGo)){
                        if((presentPlayer.playerPosition)>=(self.viewNumber*3)&&(presentPlayer.playerPosition)<(self.viewNumber+1)*3){//在可視範圍中
                            [[self.image_photo_blink objectAtIndex:((presentPlayer.playerPosition)%3+self.whoseTurn*3)] startAnimating];//顏色正確的燈閃出來
                        }
                    }
                }
            }
        }
    }else if(blinkAnimationTypeInput==blinkAnimationType_questionCard_1){//問題卡初始化，所有都變成白色
        HPPrimitiveType *primitiveTemp=[self.questionCardSelected objectAtIndex:self.viewNumber];
        if(!primitiveTemp.Boolean){//如果自己沒被按過了，才顯示白圈
            [[self.image_questionCard_blink objectAtIndex:0] startAnimating];
        }
    }else if(blinkAnimationTypeInput==blinkAnimationType_questionCard_2){//blinkAnimationState_on:只剩一個顏色再閃，其他都暗掉,
                                                                         //blinkAnimationState_off: 全部都暗掉
        int i;
        for(i=0;i<=4;i++){//全關
            [[self.image_questionCard_blink objectAtIndex:i] stopAnimating];
        }
        //這個管控在buttonHit_questionCard就做掉了，所以這邊只要直接閃或停就好了
        if(blinkAnimationStateInput==blinkAnimationState_on){
            [[self.image_questionCard_blink objectAtIndex:self.whoseTurn+1] startAnimating];
        }else if(blinkAnimationStateInput==blinkAnimationState_off){
        }
    }

}

//換新使用者
-(void)playerHandoff{
    if (viewDidLoadHandoff==NO) {
        NSMutableData *data = [NSMutableData dataWithCapacity:1];
        char messageType = gkMessageHandoffInfo;
        [data appendBytes:&messageType length:1];
        [self sendData:data useSession:session];
    }
    NSLog(@"handoff before %d", self.stepToGo);
    //##之後影片那些也還要做初始化
    self.overallRound+=1;
    self.whoseTurn=(self.whoseTurn+1)%self.playerNumber;
    self.gameState=gameState_throwDice;
    [self stepToGoDisplay];
    [self blinkAnimationFor:blinkAnimationType_photo andFocus:UNIMPORTANT andState:blinkAnimationState_off];//把全部的地圖燈都關掉
    if(self.viewNumber==1){
        [self button_toolbar_number_darkener];
    }
    self.stepToGo=0;
    [self backgroundColorReset:0];
    [self resetAllIconInState:3 andFocusedPlayer:self.whoseTurn];//先變成箭頭來提醒現在的使用者
    NSLog(@"handoff end %d", self.stepToGo);
}

-(void)playerHandoffFromRemote{
    //##之後影片那些也還要做初始化
    NSLog(@"handoff before rm %d", self.stepToGo);
    self.overallRound+=1;
    self.whoseTurn=(self.whoseTurn+1)%self.playerNumber;
    self.gameState=gameState_throwDice;
    [self stepToGoDisplay];
    [self blinkAnimationFor:blinkAnimationType_photo andFocus:UNIMPORTANT andState:blinkAnimationState_off];//把全部的地圖燈都關掉
    if(self.viewNumber==1){
        [self button_toolbar_number_darkener];
    }
    self.stepToGo=0;
    [self backgroundColorReset:0];
    [self resetAllIconInState:3 andFocusedPlayer:self.whoseTurn];//先變成箭頭來提醒現在的使用者
    NSLog(@"handoff end rm %d", self.stepToGo);
}

//顯示那個「走x步」的，含判斷及顯示
-(void)stepToGoDisplay{
    
    HPPlayer *nowPlayer=[self.playerList objectAtIndex:self.whoseTurn];
    
    if(self.whoseTurn==playerColor_orange||self.whoseTurn==playerColor_green){//如果面對的是橘、綠，則水平的那個會翻轉180度
        self.button_stepIndicator.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0));
    }else{
        self.button_stepIndicator.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0));
    }

    
    if (self.gameState==gameState_throwDice) {//throwDice時顯示「請擲骰」
        if(nowPlayer.playerPosition>=(self.viewNumber+1)*3||nowPlayer.playerPosition<self.viewNumber*3){
            [self.button_stepIndicator setImage:[UIImage imageNamed:@"transparent"]];
//            NSLog(@"消失1");
        }else{
//            if(self.whoseTurn!=playerColor_blue){//正常情況，顯示水平的
                [self.button_stepIndicator setImage:[self.stepImageList objectAtIndex:6]];
//            }else{//如果是藍色的狀況，就要顯示成垂直的
//                [self.button_stepIndicator setImage:[self.stepImageList objectAtIndex:13]];
//            }
        }
    }else if(self.gameState==gameState_moveForward){//顯示步數
        [self blinkAnimationFor:blinkAnimationType_photo andFocus:UNIMPORTANT andState:blinkAnimationState_on];
        //要position有在可視範圍內才顯示
        if(nowPlayer.playerPosition>=(self.viewNumber+1)*3||nowPlayer.playerPosition<self.viewNumber*3||self.stepToGo==0){
            NSLog(@"我在這");
            [self.button_stepIndicator setImage:[UIImage imageNamed:@"transparent"]];
        }else{
//            if(self.whoseTurn!=playerColor_blue){//正常情況，顯示水平的
                [self.button_stepIndicator setImage:[self.stepImageList objectAtIndex:(self.stepToGo-1)]];
            NSLog(@"in it  %d %@",self.stepToGo,[self.stepImageList objectAtIndex:(self.stepToGo-1)]);
//            }else{//如果是藍色的狀況，就要顯示成垂直的
//                [self.button_stepIndicator setImage:[self.stepImageList objectAtIndex:(self.stepToGo+7-1)]];
//            }
        }
    }
    
}

- (IBAction)buttonHit_photo:(id)sender{
   
    
    //現在按到的photo，在0~11的position裡面的位置
    int globalPressedPosition;
    
    if (hitPhotoFromRemote == NO) {
        UIButton *inputButton=(UIButton *)sender;
        NSLog(@"%d",inputButton.tag);
        globalPressedPosition=inputButton.tag-tag_button_photo_0+self.viewNumber*3;
        
        NSMutableData *data = [NSMutableData dataWithCapacity:1 + sizeof(HitPhotoInfo)];
        char messageType = gkMessageHitPhotoInfo;
        [data appendBytes:&messageType length:1];
        HitPhotoInfo message;
        message.globalPressedPositionTrs = globalPressedPosition;
        [data appendBytes:&message length:sizeof(HitPhotoInfo)];
        [self sendData:data useSession:session];
    }else{
        globalPressedPosition = hitPhotoInfoMessage.globalPressedPositionTrs;
        hitPhotoFromRemote = NO;
    }
    NSLog(@"pos %d", globalPressedPosition);
    
    //在gameState_throwDice時，使用者按到他應該按的photo時進入下一個state
    //即「長輩把自己的棋子放到剛剛走到的地方」這個動作
    HPPlayer *presentTurnPlayer=[self.playerList objectAtIndex:self.whoseTurn];
    if(self.gameState==gameState_throwDice){
        if(presentTurnPlayer.playerPosition==globalPressedPosition&&self.stepToGo!=0){//按對了棋子所在地，就把燈關掉。如果step是0代表還沒有按數字，也不能讓他動
            [self resetAllIconInState:3 andFocusedPlayer:self.whoseTurn];
            self.gameState=gameState_moveForward;
            [self stepToGoDisplay];
        }
    }else if(self.gameState==gameState_moveForward){
        if((presentTurnPlayer.playerPosition+1)%12==globalPressedPosition){//成功前進
            int j;
            //以下是拿來測，下一步要站的地方有沒有人在，有人在的話那就繼續往下走
            BOOL advanceMore=NO;
            HPPlayer *comparePlayer;
            for(j=0;j<self.playerNumber;j++){
                comparePlayer=[self.playerList objectAtIndex:j];
                if(j!=self.whoseTurn&&
                   (comparePlayer.playerPosition==(presentTurnPlayer.playerPosition+1)%12)){
                    advanceMore=YES;
                 }
            }
            if(!(advanceMore&&self.stepToGo==1)){//只有在剩下一步要走時，才會不扣掉剩下的步數
                self.stepToGo=self.stepToGo-1;
            }
            if(self.stepToGo==0){
                presentTurnPlayer.playerPosition=(presentTurnPlayer.playerPosition+1)%12;
                [self resetAllIconInState:1 andFocusedPlayer:self.whoseTurn];//走到了，所以變成圓形
                [self stepToGoDisplay];

                switch (presentTurnPlayer.playerPosition) {//##還有一堆state沒做
                    case 1://影片
                        // 呼叫movie
                        // self.delayTimerEvent=delayTimerEventType_video ;
                        // self.gameState=gameState_movieDisplayInitialization;
                        // break;
                        
                    case 4://音樂
                        // 呼叫music
                        // self.delayTimerEvent=delayTimerEventType_music;
                        // self.gameState=gameState_musicDisplayInitialization;
                        // break;
                        
                    case 7://機會
                        // 呼叫chance
                         self.delayTimerEvent=delayTimerEventType_chance;
                         self.gameState=gameState_chanceDisplayInitialization;
                         break;
                    case 10://遊戲
                        
//                        self.gameState=gameState_pogInitialization;
//                        self.delayTimerEvent=delayTimerEventType_game;
//
//                        break;
                        
                        // 呼叫chance
                        self.delayTimerEvent=delayTimerEventType_chance;
                        self.gameState=gameState_chanceDisplayInitialization;
                        break;
                        
                    default://一般的照片
                        self.gameState=gameState_photoDisplay;//要先改state，不然在timer等待時間誤觸到其他photo就爛了
                        self.delayTimerEvent=delayTimerEventType_photo;
                        break;
                }

                [NSTimer scheduledTimerWithTimeInterval:1 //要用timer的話就用這行
                                                 target:self
                                               selector:@selector(timerEvent:)
                                               userInfo:nil
                                                repeats:NO];
            }else{
                presentTurnPlayer.playerPosition=(presentTurnPlayer.playerPosition+1)%12;
                [self resetAllIconInState:3 andFocusedPlayer:self.whoseTurn];
                [self stepToGoDisplay];
            }
        }
    }
    
}

- (IBAction)buttonHit_questionCard:(id)sender{
    UIButton *inputButton=(UIButton *)sender;
    NSLog(@"%d",inputButton.tag);
    switch (self.gameState) {
        case gameState_chanceDisplayOutside://母牌要進入子牌
            if(inputButton.tag==tag_button_questionCard_circle){
                
                
                //把自己的那個圓形的燈開亮一下
                [self blinkAnimationFor:blinkAnimationType_questionCard_2 andFocus:UNIMPORTANT andState:blinkAnimationState_on];
                
                //$$下行廣播給所有人聽，改他們的self.questionCardSelectedNumber為此台的self.viewNumber
                self.questionCardSelectedNumber=self.viewNumber;//現在是自己被選到
                
                NSMutableData *data = [NSMutableData dataWithCapacity:1 + sizeof(QuestionCardHitInfo)];
                char messageType = gkMessageQuestionCardHit;
                [data appendBytes:&messageType length:1];
                QuestionCardHitInfo message;
                message.questionCardSelectedNumberTrs = self.questionCardSelectedNumber;
                [data appendBytes:&message length:sizeof(QuestionCardHitInfo)];
                [self sendData:data useSession:session];
                
                [NSTimer scheduledTimerWithTimeInterval:1
                                                 target:self
                                               selector:@selector(timerEvent:)
                                               userInfo:nil
                                                repeats:NO];
                
            }
            break;
        case gameState_chanceDisplayInside://子牌要回到母牌
            if(inputButton.tag==tag_button_questionCard_correct){//答對了
                //##播放你好棒
                
                int i;
                for(i=0;i<=4;i++){
                    [[self.imageView_veryGood objectAtIndex:i] setHidden:NO];
                }
                
                HPPrimitiveType *ptTemp=[self.questionCardSelected objectAtIndex:self.viewNumber];
                ptTemp.Boolean=YES;//答對之後黑掉
                
                
                for(i=1;i<=2;i++){//這行寫的有點爛，總之是為了把兩個按鈕拔掉，但是寫了第二次
                    [[self.button_questionCard objectAtIndex:i] setHidden:YES];
                }
                
                self.delayTimerEvent=delayTimerEventType_chanceVeryGood;
                [NSTimer scheduledTimerWithTimeInterval:2 //要用timer的話就用這行
                                                 target:self
                                               selector:@selector(timerEvent:)
                                               userInfo:nil
                                                repeats:NO];
                
                NSMutableData *data = [NSMutableData dataWithCapacity:1];
                char messageType = gkMessageQuestionCardRight;
                [data appendBytes:&messageType length:1];
                [self sendData:data useSession:session];
                
            }else if(inputButton.tag==tag_button_questionCard_wrong){//答錯了
                //$$廣播給所有人
                [self showChance:2 andTarget:UNIMPORTANT];
                
                NSMutableData *data = [NSMutableData dataWithCapacity:1];
                char messageType = gkMessageQuestionCardWrong;
                [data appendBytes:&messageType length:1];
                [self sendData:data useSession:session];
            }
            break;
        default:
            break;
    }
    
}
-(void)showPhoto:(NSInteger)stateInput{
    //state 0:不顯示
    //      1:顯示
    
    
    if(stateInput==1){
//    以下為開始顯示相框及照片
    
     CGAffineTransform transform_0deg = CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0));
     CGAffineTransform transform_90deg = CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0));
     CGAffineTransform transform_270deg = CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0));
    
     self.albumPhoto.transform=transform_0deg;//先把轉動歸零
//     if(self.whoseTurn==playerColor_blue){//blue時，顯示相框的方式不同，##未完成：沒有照片時也是
//         [self.albumFrame setImage:self.albumFrame_potrait];
//         
//         [self.albumPhoto setImage:[[self.imageLoadedList objectAtIndex:self.whoseTurn] objectAtIndex:0]];
//         if(self.viewNumber==0||self.viewNumber==3){
//             self.albumPhoto.frame=CGRectMake(96,270, 663, 502);
//         }else{
//             self.albumPhoto.frame=CGRectMake(26,260, 663, 502);
//         }
//     //長的：663,502(1,2機:26,260)(0,3機：96,270)
//     //橫的：830,679(1,2機:55,34)(0,3機：142,49)
//     }else{
         [self.albumFrame setImage:self.albumFrame_horizontal];
         [self.albumPhoto setImage:[[self.imageLoadedList objectAtIndex:self.whoseTurn] objectAtIndex:0]];
         
         if(self.whoseTurn==playerColor_red||self.whoseTurn==playerColor_yellow){
             self.albumPhoto.transform=transform_90deg;//照片面向左邊的情況
         }else{
             self.albumPhoto.transform=transform_270deg;//照片面向右邊的情況
         }
         
         if(self.viewNumber==0||self.viewNumber==1){
             self.albumPhoto.frame=CGRectMake(44,52, 676, 830);
         }else{
             self.albumPhoto.frame=CGRectMake(44,140, 676, 830);
             
             //轉動之後判斷圖片的機制：左上角仍然是錨點，然後長寬方向也是按照原先ipad的長寬。可以把它想成決定框架的大小，裡面圖片怎麼轉隨便他。
             //另外，如果frame先於transform，則就變成先填圖再轉，用這個方法就可以不用管轉成45度角時奇怪的長高，應該是比較好的方法
         }
     
//     }
    }else if(stateInput==0){//取消顯示ㄅ
        [self.albumFrame setImage:[UIImage imageNamed:@"transparent"]];
        [self.albumPhoto setImage:[UIImage imageNamed:@"transparent"]];
    }

}
-(void)showChance:(NSInteger)stateInput andTarget:(int)targetViewNumber{//Chance進來了,targetViewNumber是按到哪張子牌
    //state EXIT:不顯示
    // 1:初始化(第一次顯示母牌)
    // 2:正常顯示母牌(第二次以後)
    // 3:顯示子牌
    int i;
    HPPrimitiveType *boolTemp;
    switch (stateInput) {
        case EXIT:
            [self.questionCard setHidden:YES];
            [self.questionCard_black setHidden:YES];
            for(i=0;i<=2;i++){
                [[self.button_questionCard objectAtIndex:i] setHidden:YES];
            }
            [self blinkAnimationFor:blinkAnimationType_questionCard_2 andFocus:UNIMPORTANT andState:blinkAnimationState_off];//把全部關掉
            break;
        case 1://initialization，顯示母牌
            self.questionCardSelected=[[NSMutableArray alloc] initWithCapacity:4];
            for (i=0;i<=3;i++){//第一次碰前，先把四個都初始化成沒按過
                boolTemp=[[HPPrimitiveType alloc] init];
                boolTemp.Boolean=NO;
                [self.questionCardSelected addObject:boolTemp];
            }
            self.questionCardSelectedNumber=0;
            [self.questionCard setImage:[self.image_questionCard objectAtIndex:0]];//顯示母牌
            [self.questionCard setHidden:NO];//幹之前都不知道有hidden這個屬性這麼方便可以把東西直接藏起來，還用成transparent真的太白痴了
            [[self.button_questionCard objectAtIndex:0] setHidden:NO];
            
            [self blinkAnimationFor:blinkAnimationType_questionCard_1 andFocus:UNIMPORTANT andState:UNIMPORTANT];//把全部開亮
            self.gameState=gameState_chanceDisplayOutside;
            
            break;
            
        case 2://正常顯示母牌
            
            boolTemp=[self.questionCardSelected objectAtIndex:self.viewNumber];
            if(boolTemp.Boolean){//若自己已經被按過了：變暗，不翻回來
                [self.questionCard_black setHidden:NO];
                [[self.button_questionCard objectAtIndex:0] setHidden:YES];//把中間那個透明按鈕隱藏起來別人就按不到了
            }else{
                [self.questionCard_black setHidden:YES];
                [[self.button_questionCard objectAtIndex:0] setHidden:NO];
                for(i=1;i<=2;i++){
                    [[self.button_questionCard objectAtIndex:i] setHidden:YES];
                }
                
                [self.questionCard setImage:[self.image_questionCard objectAtIndex:0]];//顯示母牌
                [self blinkAnimationFor:blinkAnimationType_questionCard_1 andFocus:UNIMPORTANT andState:UNIMPORTANT];//把全部開亮
            }
            self.gameState=gameState_chanceDisplayOutside;
            break;
            
        case 3://有人要顯示子牌
            boolTemp=[self.questionCardSelected objectAtIndex:self.viewNumber];
            if(!boolTemp.Boolean){//若自己已經被按過了：就不用管了
                [self blinkAnimationFor:blinkAnimationType_questionCard_2 andFocus:UNIMPORTANT andState:blinkAnimationState_off];//把全部關掉
                if(targetViewNumber==self.viewNumber){//如果是自己被按到的話才做事情
                    [self.questionCard setImage:[self.image_questionCard objectAtIndex:self.viewNumber+1]];//##這邊之後應該要用亂數
                    // 但之前寫的也懶得改了...
                    [[self.button_questionCard objectAtIndex:0] setHidden:YES];//把中間那格停掉
                    //把OX開出來
                    for(i=1;i<=2;i++){
                        [[self.button_questionCard objectAtIndex:i] setHidden:NO];
                    }
                }else{
                    [self.questionCard_black setHidden:NO];
                }
            }
            self.gameState=gameState_chanceDisplayInside;
            
            break;
        default:
            break;
    }
}
-(void)addButtonWithImage:(NSString*)imageName andRect:(CGRect)rectInput andTag:(UIViewTag)tagInput andType:(buttonType)buttonTypeInput{
    
    //旋轉用trasform
    CGAffineTransform transform_180deg = CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0));
    
    UIButton *buttonTemp = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [buttonTemp setBackgroundImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    
    
    //四個數值表：錨定點x,錨定點y,圖寬,圖高
    
    buttonTemp.tag=tagInput;
    buttonTemp.frame=rectInput;
    
    //如果是工具列的那就轉180度
    if(buttonTypeInput==buttonType_toolbar_function||
       buttonTypeInput==buttonType_toolbar_number){
        buttonTemp.transform = transform_180deg;
    }
    
    //1.button加入listener
    //2.button加入array中監視
    switch (buttonTypeInput) {
        case buttonType_toolbar_function:
            [buttonTemp addTarget:self action:@selector(buttonHit_toolbar_function:) forControlEvents:UIControlEventTouchUpInside];
            switch (buttonTemp.tag) {//順調一下按下去的狀態
                case tag_button_toolbar_0_map:
                    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"back_to_map_press"] forState:UIControlEventTouchDown];
                    break;
                case tag_button_toolbar_4_backward:
                    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"backward_press"] forState:UIControlEventTouchDown];
                    break;
            }
            [self.button_toolbar_function addObject:buttonTemp];
            break;
        case buttonType_toolbar_number:
            [buttonTemp addTarget:self action:@selector(buttonHit_toolbar_number:) forControlEvents:UIControlEventTouchUpInside];
            
            
            [self.button_toolbar_number addObject:buttonTemp];
            break;
        case buttonType_photo:
            [buttonTemp addTarget:self action:@selector(buttonHit_photo:) forControlEvents:UIControlEventTouchDown];
            [self.button_photo addObject:buttonTemp];
            break;
        case buttonType_questionCard:
            [buttonTemp addTarget:self action:@selector(buttonHit_questionCard:) forControlEvents:UIControlEventTouchDown];
            //先隱藏這系列的按鈕
            buttonTemp.hidden=YES;
            switch (buttonTemp.tag) {//順調一下按下去的狀態
                case tag_button_questionCard_correct:
                    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"questionCard_correct_pressed"] forState:UIControlEventTouchDown];
                    break;
                case tag_button_questionCard_wrong:
                    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"questionCard_wrong_pressed"] forState:UIControlEventTouchDown];
                    break;
                default:
                    break;
            }
            [self.button_questionCard addObject:buttonTemp];
            break;
            
        case buttonType_pogPaper:
            [buttonTemp addTarget:self action:@selector(pogButtonPressed:) forControlEvents:UIControlEventTouchDown];
            buttonTemp.hidden=YES;
            [self.button_pogPaper addObject:buttonTemp];
            break;
            
        case buttonType_TEST:
            [buttonTemp addTarget:self action:@selector(buttonHit_TEST:) forControlEvents:UIControlEventTouchUpInside];
            break;
            
            
        default:
            break;
    }
    //alpha差不多0.8吧
    [self.view addSubview:buttonTemp];
    
    
}

-(void)resetAllIconInState:(NSInteger)stateInput andFocusedPlayer:(playerColor)playerInput{//重置所有棋子。順便把棋子那格打亮。
    //    state:
    //        0:不顯示
    //        1:全部皆為圓形
    //        2:有一個為箭頭(playerInput為變箭頭的那個)with光圈
    //        3:有一個為箭頭(playerInput為變箭頭的那個)without光圈
    
    int i;
    int stateTemp=stateInput;
    BOOL state2=(stateInput==2||stateInput==3)?YES:NO;//看是不是state2
    stateInput=(stateInput==2||stateInput==3)?1:stateInput;//節省行數。因為state2事實上也只有一個focused的人是要變成箭頭
    HPPlayer *playerTemp;
    
    UIButton *buttonTemp;
    for(i=0;i<=2;i++){//先把所有都變黑
        NSLog(@"在這哦");
        buttonTemp=[self.button_photo objectAtIndex:i];
        [buttonTemp setAlpha:0.8f];
    }
    playerTemp=[self.playerList objectAtIndex:self.whoseTurn];//再把要的白回來
    if(playerTemp.playerPosition<(self.viewNumber+1)*3&&playerTemp.playerPosition>=self.viewNumber*3){
        buttonTemp=[self.button_photo objectAtIndex:playerTemp.playerPosition%3];
        [buttonTemp setAlpha:1.0f];
    }
    
    for(i=0;i<self.playerNumber;i++){
        if(i<=self.overallRound){//第一回合，還沒出現的棋子就不顯示
            playerTemp=[self.playerList objectAtIndex:i];
            [self changeIconPlayer:i andPosition:playerTemp.playerPosition andState:stateInput];
        }
    }

    //如果輪到他的話就變成箭頭
    playerTemp=[self.playerList objectAtIndex:playerInput];
    if(state2){
        [self changeIconPlayer:playerInput andPosition:playerTemp.playerPosition andState:stateTemp];
    }
    


}

//移動/改變使用者的棋子（單個）
-(void)changeIconPlayer:(playerColor)playerInput andPosition:(NSInteger)positionInput andState:(NSInteger)stateInput{
//    state:fstep
//        0:不顯示
//        1:正常圓圈
//        2:圓圈with箭頭with光圈
//        3:圓圈with箭頭without光圈
    UIImageView *iconTemp=[self.image_icon objectAtIndex:playerInput];
    NSLog(@"誰傳進來：%d,位置：%d,state:%d",(int)playerInput,(int)positionInput,stateInput);
    //要position有在可視範圍內才顯示
    if(positionInput>=(self.viewNumber+1)*3||positionInput<self.viewNumber*3){
        stateInput=0;
    }
    
    
    if(stateInput==0){
        [iconTemp setImage:[UIImage imageNamed:@"transparent"]];
        [self blinkAnimationFor:blinkAnimationType_icon andFocus:UNIMPORTANT andState:blinkAnimationState_off];//其實關動畫的時候Focus沒有用
    }else if(stateInput==1){
        [self blinkAnimationFor:blinkAnimationType_icon andFocus:UNIMPORTANT andState:blinkAnimationState_off];
        switch (playerInput) {
            case playerColor_red:
                [iconTemp setImage:[UIImage imageNamed:@"circle_foot_red"]];
                break;
            case playerColor_yellow:
                [iconTemp setImage:[UIImage imageNamed:@"circle_foot_yellow"]];
                break;
//            case playerColor_blue:
//                [iconTemp setImage:[UIImage imageNamed:@"circle_foot_blue"]];
//                break;
            case playerColor_green:
                [iconTemp setImage:[UIImage imageNamed:@"circle_foot_green"]];
                break;
            case playerColor_orange:
                [iconTemp setImage:[UIImage imageNamed:@"circle_foot_orange"]];
                break;
            default:
                break;
        }
        
        iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0));//一定要歸零，不然會變成transform在frame前
        switch (positionInput) {
            case 0:
                iconTemp.frame=CGRectMake(468, 706, 249, 252);
                break;
            case 1:
                iconTemp.frame=CGRectMake(417,211, 249, 252);
                break;
            case 2:
                iconTemp.frame=CGRectMake(53,163, 249, 252);
                break;
            case 3:
                iconTemp.frame=CGRectMake(458,163, 249, 252);
                break;
            case 4:
                iconTemp.frame=CGRectMake(111,211, 249, 252);
                break;
            case 5:
                iconTemp.frame=CGRectMake(47,706, 249, 252);
                break;
            case 6:
                iconTemp.frame=CGRectMake(47,110, 249, 252);
                break;
            case 7:
                iconTemp.frame=CGRectMake(76,557, 249, 252);
                break;
            case 8:
                iconTemp.frame=CGRectMake(458,681, 249, 252);
                break;
            case 9:
                iconTemp.frame=CGRectMake(53,681, 249, 252);
                break;
            case 10:
                iconTemp.frame=CGRectMake(417,557, 249, 252);
                break;
            case 11:
                iconTemp.frame=CGRectMake(468,110, 249, 252);
                break;
            default:
                break;
        }
    }else if(stateInput==2||stateInput==3){
        switch (playerInput) {
            case playerColor_red:
                [iconTemp setImage:[UIImage imageNamed:@"arrow_foot_red"]];
                break;
            case playerColor_yellow:
                [iconTemp setImage:[UIImage imageNamed:@"arrow_foot_yellow"]];
                break;
//            case playerColor_blue:
//                [iconTemp setImage:[UIImage imageNamed:@"arrow_foot_blue"]];
//                break;
            case playerColor_green:
                [iconTemp setImage:[UIImage imageNamed:@"arrow_foot_green"]];
                break;
            case playerColor_orange:
                [iconTemp setImage:[UIImage imageNamed:@"arrow_foot_orange"]];
                break;
            default:
                break;
        }
        iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0));//一定要歸零，不然會變成transform在frame前面，整個圖就會被扭曲了。
        switch (positionInput) {
            case 0:
                iconTemp.frame=CGRectMake(468, 650, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0));
                break;
            case 1:
                iconTemp.frame=CGRectMake(417,180, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(315.0));
                break;
            case 2:
                iconTemp.frame=CGRectMake(73,113, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0));
                break;
            case 3:
                iconTemp.frame=CGRectMake(458,113, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0));
                break;
            case 4:
                iconTemp.frame=CGRectMake(111,180, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(225.0));
                break;
            case 5:
                iconTemp.frame=CGRectMake(47,600, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0));
                break;
            case 6:
                iconTemp.frame=CGRectMake(47,40, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0));
                break;
            case 7:
                iconTemp.frame=CGRectMake(100,500, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(135.0));
                break;
            case 8:
                iconTemp.frame=CGRectMake(438,600, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0));
                break;
            case 9:
                iconTemp.frame=CGRectMake(53,600, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0));
                break;
            case 10:
                iconTemp.frame=CGRectMake(417,500, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(45.0));
                break;
            case 11:
                iconTemp.frame=CGRectMake(468,50, 252, 402);
                iconTemp.transform=CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0));
                break;
            default:
                break;
        }
        if(stateInput==2){
            [self blinkAnimationFor:blinkAnimationType_icon andFocus:positionInput andState:blinkAnimationState_on];
        }
        else{
            [self blinkAnimationFor:blinkAnimationType_icon andFocus:positionInput andState:blinkAnimationState_off];
        }
        

    }

}

//延遲之後要觸發哪種Event
- (void)timerEvent:(NSTimer *)timer{
    int i;
    NSLog(@"Timer!%d",self.delayTimerEvent);
    switch (self.delayTimerEvent) {
        case delayTimerEventType_photo:
            [self showPhoto:1];
            break;
        case delayTimerEventType_chance:
            switch (self.gameState) {
                case gameState_chanceDisplayInitialization:
                    //$$廣播給所有人
                    [self showChance:1 andTarget:UNIMPORTANT];
                    break;
                case gameState_chanceDisplayOutside://母牌進子牌
                    //$$廣播給所有人
                    [self showChance:3 andTarget:self.questionCardSelectedNumber];
                    break;
                default:
                    break;
            }
            break;
        case delayTimerEventType_chanceVeryGood://veryGood
            for(i=0;i<=4;i++){
                [[self.imageView_veryGood objectAtIndex:i] setHidden:YES];
            }
            //$$廣播給所有人
            [self showChance:2  andTarget:UNIMPORTANT];
            break;
            
        case delayTimerEventType_video://
            //$$廣播給所有人
            [self showMoiveAndMusic:movieAndMusicState_movieSelect andSelectedView:UNIMPORTANT];
            break;
            
        case delayTimerEventType_music://
            //$$廣播給所有人
            [self showMoiveAndMusic:movieAndMusicState_musicSelect andSelectedView:UNIMPORTANT];
            break;
            
        default:
            break;
    }
    if(self.delayTimerEvent==delayTimerEventType_photo){
        
    }
    //[timer invalidate]; //停止 Timer
}

-(void)blinkArrayAdderWithArray:(NSArray*)arrayInput andRect:(CGRect)rectInput andType:(blinkAnimationType)typeInput{//單純用來簡化加入照片的blink時的程序
    
    
    
    UIImageView *image_blink_animation;
    image_blink_animation = [UIImageView alloc];
    
    [image_blink_animation initWithFrame:rectInput];
    image_blink_animation.animationImages = arrayInput;//動畫的array
    image_blink_animation.animationDuration = 1;//動畫時間
    image_blink_animation.animationRepeatCount = 0;//播幾次。0表無限
    [image_blink_animation stopAnimating];//先暫停，之後點到步數再亮
    switch (typeInput) {
        case blinkAnimationType_icon:
            self.image_icon_blink=image_blink_animation;
            break;
        case blinkAnimationType_photo:
            switch (self.viewNumber) {
                case 1:
                    image_blink_animation.transform=CGAffineTransformMakeScale(-1, 1);
                    break;
                case 2:
                    image_blink_animation.transform=CGAffineTransformMakeScale(-1, -1);
                    break;
                case 3:
                    image_blink_animation.transform=CGAffineTransformMakeScale(1, -1);
                    break;
                case 0:
                default:
                    break;
            }
            [self.image_photo_blink addObject:image_blink_animation];
            break;
        case blinkAnimationType_questionCard_1:
            [self.image_questionCard_blink addObject:image_blink_animation];
            break;
        case blinkAnimationType_veryGood:
            [self.imageView_veryGood addObject:image_blink_animation];
            break;
        case blinkAnimationType_pogPaperTorn:
            image_blink_animation.animationRepeatCount = 1;//只播一次
            self.imageView_pogPaperTorn=image_blink_animation;
            break;
        default:
            break;
    }
    
    [self.view addSubview:image_blink_animation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    appDelegate=(HPAppDelegate *)[[UIApplication sharedApplication]delegate];
    session = appDelegate.gkSession;
    session.delegate = self;
    [session setDataReceiveHandler:self withContext:nil];
    session.available = YES;
    viewDidLoadHandoff = YES;
    hitPhotoFromRemote = NO;
    
    int i,j;
    
    //初始化gameState
    self.gameState=gameState_throwDice;
    self.whoseTurn=playerColor_orange;
    self.toolbarLightOn=YES;//其實剛開始會把燈還有音樂都打開，只是會在下面做
    self.toolbarMusicOn=YES;
    self.playerNumber=4;//##我沒有很認真把每個東西都修成能夠適應其他人數的狀態，所以現在self.playerNumber就跟4意思一模一樣
    self.overallRound=-1;
    self.toolbarPlayerState=playerStateType_none;
    self.stepToGo=0;
    
    
    self.delayTimerEvent=delayTimerEventType_none;
    
    //初始化各ImageView
    self.backgroundImageList=[[NSMutableArray alloc]initWithCapacity:self.playerNumber];
    [self.backgroundImageList addObject:[UIImage imageNamed:@"color_R"]];
    [self.backgroundImageList addObject:[UIImage imageNamed:@"color_Y"]];
    //    [self.backgroundImageList addObject:[UIImage imageNamed:@"color_B"]];
    [self.backgroundImageList addObject:[UIImage imageNamed:@"color_G"]];
    [self.backgroundImageList addObject:[UIImage imageNamed:@"color_O"]];
    [self.backgroundImageList addObject:[UIImage imageNamed:@"pog_table"]];
    
    self.backgroundColor = [[UIImageView alloc] initWithImage:[self.backgroundImageList objectAtIndex:0]];
    self.backgroundColor.frame=CGRectMake(0,0, 768, 1024);
    [self.view addSubview:self.backgroundColor];
    [self backgroundColorReset:0];
    
    
    
    //把照片全部load進來
    self.imageLoadedList=[[NSMutableArray alloc] initWithCapacity:self.playerNumber];
    
    for(i=0;i<=5;i++){
        //其實總共要有5(人)x8(地點)x4(張照片)=160張，先假設每個使用者每個地點的照片都一樣，所以先放20張，然後地點都是0(中間那碼數字)
        //      P_ 0 _  0    _  0 .png
        //每台只要load會顯示在自己機台的照片，即最後一碼。
        //引導者使用的預設照片放在5裡面，暫時用不到
        NSMutableArray *secondLayer=[[NSMutableArray alloc] initWithCapacity:8];
        //        for (j=0; j<=7; j++) { //這邊先沒有根據地點選進來
        if(i!=4){//非管理者顯示的情況
            //要成功切，除了圖片大小要對之外，frame也要配合
            //JPG一定要寫完整附檔名
            [secondLayer addObject:[UIImage imageNamed:[NSString stringWithFormat:@"P%d_0_%d.jpg",i,self.viewNumber]]];
        }else{
            [secondLayer addObject:[UIImage imageNamed:[NSString stringWithFormat:@"P%d_0_%d.jpg",i,self.viewNumber]]];
        }
        //        }
        [self.imageLoadedList addObject:secondLayer];//這樣兩層是存：1.人 2.地點
        
        //長的：663,502
        //橫的：830,679
        
    }
    
    
    
    
    
    //走路的button ---------------------------------
    
    
    //    前一碼-四個分配(照逆時針):
    //
    //        1 -- 0
    //        |    |
    //        2 -- 3
    //
    //    後一碼-每個裡面的分配(照逆時針):
    //
    //        0:
    //            2-
    //               1
    //                0
    //
    //
    //        1:
    //               -0
    //             1
    //            2
    //
    //
    //        2:
    //            0
    //             1
    //               -2
    //
    //
    //        3:
    //                2
    //               1
    //            0-
    //
    //
    //
    //      每個人position:
    //
    //        4-3-2-1
    //        5     0
    //        6     11
    //        7-8-9-10
    //
    
    
    
    //加入格子背景的黑色
    UIImageView *photo_background_black_A;
    UIImageView *photo_background_black_B;
    UIImageView *photo_background_black_C;
    
    photo_background_black_A =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_light_background_A"]];
    photo_background_black_B =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_light_background_B"]];
    photo_background_black_C =[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_light_background_C"]];
    
    
    switch (self.viewNumber) {
        case 0:
            photo_background_black_A.frame=CGRectMake(449,620, 287, 379);
            photo_background_black_B.frame=CGRectMake(373,78, 364, 512);
            photo_background_black_C.frame=CGRectMake(25,80, 315, 351);
            break;
            
        case 1:
            photo_background_black_B.transform=CGAffineTransformMakeScale(-1, 1);
            photo_background_black_A.frame=CGRectMake(429,77, 317, 353);
            photo_background_black_B.frame=CGRectMake(34,77, 364, 511);
            photo_background_black_C.frame=CGRectMake(34,619, 288, 381);
            break;
            
        case 2:
            photo_background_black_B.transform=CGAffineTransformMakeScale(-1, -1);
            photo_background_black_A.frame=CGRectMake(32,25, 287, 378);
            photo_background_black_B.frame=CGRectMake(33,435, 365, 511);
            photo_background_black_C.frame=CGRectMake(429,591, 315, 350);
            break;
            
        case 3:
            photo_background_black_B.transform=CGAffineTransformMakeScale(1, -1);
            photo_background_black_A.frame=CGRectMake(26,590, 315, 350);
            photo_background_black_B.frame=CGRectMake(374,433, 364, 511);
            photo_background_black_C.frame=CGRectMake(452,25, 286, 379);
            break;
            
        default:
            break;
    }
    
    [self.view addSubview:photo_background_black_A];
    [self.view addSubview:photo_background_black_B];
    [self.view addSubview:photo_background_black_C];
    
    
    
    //button：三個圖片
    CGRect rect_photo_0;
    CGRect rect_photo_1;
    CGRect rect_photo_2;
    
    
    
    //設定三個圖片在的位置
    switch(self.viewNumber){
        case 0:
            rect_photo_0=CGRectMake(449,620, 287, 379);
            rect_photo_1=CGRectMake(373,78, 364, 512);
            rect_photo_2=CGRectMake(25,80, 315, 351);
            break;
        case 1:
            rect_photo_0=CGRectMake(429,77, 317, 353);
            rect_photo_1=CGRectMake(34,77, 364, 511);
            rect_photo_2=CGRectMake(34,619, 288, 381);
            break;
        case 2:
            rect_photo_0=CGRectMake(32,25, 287, 378);
            rect_photo_1=CGRectMake(33,435, 365, 511);
            rect_photo_2=CGRectMake(429,591, 315, 350);
            break;
        case 3:
            rect_photo_0=CGRectMake(26,590, 315, 350);
            rect_photo_1=CGRectMake(374,433, 364, 511);
            rect_photo_2=CGRectMake(452,25, 286, 379);
            break;
        default:
            break;
    }
    
    self.button_photo=[[NSMutableArray alloc] initWithCapacity:3];
    
    [self addButtonWithImage:[NSString stringWithFormat:@"map_light_%d_0",self.viewNumber] andRect:rect_photo_0 andTag:(tag_button_photo_0) andType:buttonType_photo];
    [self addButtonWithImage:[NSString stringWithFormat:@"map_light_%d_1",self.viewNumber] andRect:rect_photo_1 andTag:(tag_button_photo_1) andType:buttonType_photo];
    [self addButtonWithImage:[NSString stringWithFormat:@"map_light_%d_2",self.viewNumber] andRect:rect_photo_2 andTag:(tag_button_photo_2) andType:buttonType_photo];
    
    
    
    //走路的button結束 ------------------------------
    
    
    UIImageView *woodRail;
    woodRail=[[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"woodRails_%d",self.viewNumber]]];
    switch (self.viewNumber) {
        case 0:
            woodRail.frame=CGRectMake(-1, 49, 768, 974);
            break;
        case 1:
            woodRail.frame=CGRectMake(2, 47, 768, 974);
            break;
        case 2:
            woodRail.frame=CGRectMake(0, 0, 768, 974);
            break;
        case 3:
            woodRail.frame=CGRectMake(0, 0, 768, 974);
            break;
        default:
            break;
    }
    [self.view addSubview:woodRail];
    
    
    
    //圖片周圍發亮的動畫
    self.image_photo_blink=[[NSMutableArray alloc] initWithCapacity:12];
    NSArray *image_photo_blink_array_A;
    NSArray *image_photo_blink_array_B;
    NSArray *image_photo_blink_array_C;
    for(i=0;i<4;i++){//總共要加入12個燈，排序方式是：紅0,紅1,紅2,黃0,黃1,黃2,綠0,綠1,綠2,橘0,橘1,橘2
        //每個人的0在畫面中都是不同的(如view0的第0個是長的,view1的第0個是短的)，但只要直接從Array中拿0就可以用了，旋轉之類的在這邊就全部解決掉
        
        image_photo_blink_array_A = [NSArray arrayWithObjects:
                                     [UIImage imageNamed:[NSString stringWithFormat:@"photo_light_%d_A",i]],[UIImage imageNamed:@"photo_light_W_A"],nil];
        image_photo_blink_array_B = [NSArray arrayWithObjects:
                                     [UIImage imageNamed:[NSString stringWithFormat:@"photo_light_%d_C",i]],[UIImage imageNamed:@"photo_light_W_C"],nil];
        image_photo_blink_array_C = [NSArray arrayWithObjects:
                                     [UIImage imageNamed:[NSString stringWithFormat:@"photo_light_%d_B",i]],[UIImage imageNamed:@"photo_light_W_B"],nil];
        
        
        switch (self.viewNumber) {
            case 0:
                [self blinkArrayAdderWithArray:image_photo_blink_array_A andRect:CGRectMake(417, 587, 350, 436) andType:blinkAnimationType_photo];
                [self blinkArrayAdderWithArray:image_photo_blink_array_B andRect:CGRectMake(340, 43, 428, 572) andType:blinkAnimationType_photo];
                [self blinkArrayAdderWithArray:image_photo_blink_array_C andRect:CGRectMake(-2, 43, 372, 416) andType:blinkAnimationType_photo];
                break;
            case 1:
                [self blinkArrayAdderWithArray:image_photo_blink_array_C andRect:CGRectMake(403, 40, 372, 416) andType:blinkAnimationType_photo];
                [self blinkArrayAdderWithArray:image_photo_blink_array_B andRect:CGRectMake(3, 47, 428, 572) andType:blinkAnimationType_photo];
                [self blinkArrayAdderWithArray:image_photo_blink_array_A andRect:CGRectMake(3, 586, 350, 436) andType:blinkAnimationType_photo];
                break;
            case 2:
                [self blinkArrayAdderWithArray:image_photo_blink_array_A andRect:CGRectMake(5, -2, 350, 436) andType:blinkAnimationType_photo];
                [self blinkArrayAdderWithArray:image_photo_blink_array_B andRect:CGRectMake(5, 406, 428, 572) andType:blinkAnimationType_photo];
                [self blinkArrayAdderWithArray:image_photo_blink_array_C andRect:CGRectMake(405, 560, 372, 416) andType:blinkAnimationType_photo];
                break;
            case 3:
                [self blinkArrayAdderWithArray:image_photo_blink_array_C andRect:CGRectMake(-1, 561, 372, 416) andType:blinkAnimationType_photo];
                [self blinkArrayAdderWithArray:image_photo_blink_array_B andRect:CGRectMake(344, 401, 428, 572) andType:blinkAnimationType_photo];
                [self blinkArrayAdderWithArray:image_photo_blink_array_A andRect:CGRectMake(423, 1, 350, 436) andType:blinkAnimationType_photo];
                break;
                
            default:
                break;
        }
        
    }
    
    
    
    //五個player的足跡
    self.playerList=[[NSMutableArray alloc] initWithObjects:[[HPPlayer alloc] initWithPlayer:0],[[HPPlayer alloc] initWithPlayer:1],[[HPPlayer alloc] initWithPlayer:2],[[HPPlayer alloc] initWithPlayer:3],[[HPPlayer alloc] initWithPlayer:4], nil];
    
    self.image_icon=[[NSMutableArray alloc] initWithCapacity:5];
    UIImageView *imageTemp;
    for(i=0;i<self.playerNumber;i++){
        //先加五個空白的ImageView進去，之後再直接替換
        imageTemp=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"transparent"]];
        imageTemp.tag=tag_image_icon_0+i;
        [self.image_icon addObject:imageTemp];
        [self.view addSubview:imageTemp];
    }
    
    //    //**TEST
    //    HPPlayer *playerTempA=[self.playerList objectAtIndex:0];
    //    playerTempA.playerPosition=2;
    //    [self buttonHit_toolbar_number:nil];
    //    //**TEST
    
    
    //足跡發亮的動畫
    
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"foot_light"],
                                    [UIImage imageNamed:@"transparent"],nil]
                           andRect:CGRectMake(0, 0, 231, 228) andType:blinkAnimationType_icon];
    
    //還要走幾步的提示圖
    self.button_stepIndicator = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"transparent"]];
    
    switch (self.viewNumber) {
        case 0:
            self.button_stepIndicator.frame=CGRectMake(58,514, 274, 463);
            break;
        case 1:
            self.button_stepIndicator.frame=CGRectMake(428,514, 274, 463);
            break;
        case 2:
            self.button_stepIndicator.frame=CGRectMake(428,42, 274, 463);
            break;
        case 3:
            self.button_stepIndicator.frame=CGRectMake(58,42, 274, 463);
            break;
        default:
            break;
    }
    
    //先把提示圖的UIimage預load
    //排列原則：水平1~6,水平「請擲骰」,垂直1~6，垂直「請擲骰」
    [self.view addSubview:self.button_stepIndicator];
    self.stepImageList=[[NSMutableArray alloc] initWithCapacity:14];
    UIImage *stepTemp;
    for (i=1;i<=6;i++){
        [self.stepImageList addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%d_step",i]]];
    }
    [self.stepImageList addObject:[UIImage imageNamed:@"throw_dice"]];
    for (i=1;i<=6;i++){
        [self.stepImageList addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%d_step_v",i]]];
    }
    [self.stepImageList addObject:[UIImage imageNamed:@"throw_dice_v"]];
    
    
    //load之後要顯示的相框跟相片所在地
    
    if(self.viewNumber==0||self.viewNumber==3){//先load進來之後就不用再load了
        self.albumFrame_potrait=[UIImage imageNamed:@"albumB_2"];
    }else{
        self.albumFrame_potrait=[UIImage imageNamed:@"albumB_1"];
    }
    
    if(self.viewNumber==0||self.viewNumber==1){//先load進來之後就不用再load了
        self.albumFrame_horizontal=[UIImage imageNamed:@"albumA_1"];
    }else{
        self.albumFrame_horizontal=[UIImage imageNamed:@"albumA_2"];
    }
    
    
    self.albumPhoto = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"transparent"]];
    self.albumPhoto.frame=CGRectMake(0,0, 768, 1024);
    [self.view addSubview:self.albumPhoto];
    
    self.albumFrame = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"transparent"]];
    self.albumFrame.frame=CGRectMake(0,0, 768, 1024);
    [self.view addSubview:self.albumFrame];
    
    //讀取問題卡的圖片
    self.image_questionCard=[[NSMutableArray alloc] initWithCapacity:5];
    [self.image_questionCard addObject:[UIImage imageNamed:@"questionCardM"]];//第0張是母卡，1~4目前是問題卡
    
    for (i=0;i<4;i++){//##這邊之後應該是要可以亂數(假設一切順利到能建立那個網站的話)
        [self.image_questionCard addObject:[UIImage imageNamed:[NSString stringWithFormat:@"questionCard_%d",i]]];
    }
    self.questionCard=[[UIImageView alloc]initWithImage:[self.image_questionCard objectAtIndex:0]];
    switch (self.viewNumber) {
        case 0:
        case 1:
            self.questionCard.frame=CGRectMake(0, 47, 768, 978);
            break;
        case 2:
        case 3:
            self.questionCard.frame=CGRectMake(0, 0, 768, 1024);
            break;
            
        default:
            break;
    }
    
    [self.view addSubview:self.questionCard];
    [self.questionCard setHidden:YES];
    
    //先塞你好棒的四個背景顏色進去
    self.image_veryGood_background=[[NSMutableArray alloc] initWithCapacity:4];
    [self.image_veryGood_background addObject:[UIImage imageNamed:@"veryGood_background_R"]];
    [self.image_veryGood_background addObject:[UIImage imageNamed:@"veryGood_background_Y"]];
    [self.image_veryGood_background addObject:[UIImage imageNamed:@"veryGood_background_G"]];
    [self.image_veryGood_background addObject:[UIImage imageNamed:@"veryGood_background_O"]];
    
    //你好棒的ImageView:
    //0:底色
    //1:shine
    //2:main手
    //3:燈泡
    //4:燈閃閃
    self.imageView_veryGood=[[NSMutableArray alloc] initWithCapacity:5];
    UIImageView *imageViewTemp=[[UIImageView alloc] initWithImage:[self.image_veryGood_background objectAtIndex:0]];
    imageViewTemp.frame=CGRectMake(0,0,768,1024);
    [self.imageView_veryGood addObject:imageViewTemp];
    
    imageViewTemp=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"veryGood_shine"]];
    imageViewTemp.frame=CGRectMake(-488,-650,1754,2481);
    [self.imageView_veryGood addObject:imageViewTemp];
    
    imageViewTemp=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"veryGood_light_bulb"]];
    imageViewTemp.frame=CGRectMake(56,180,666,663);//
    [self.imageView_veryGood addObject:imageViewTemp];
    
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"veryGood_light_light"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:CGRectMake(56,180,666,663)
                           andType:blinkAnimationType_veryGood];
    [[self.imageView_veryGood objectAtIndex:3] startAnimating];
    imageViewTemp=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"veryGood_main"]];
    imageViewTemp.frame=CGRectMake(119,243,540,538);
    [self.imageView_veryGood addObject:imageViewTemp];
    
    for(i=0;i<=4;i++){
        [self.view addSubview:[self.imageView_veryGood objectAtIndex:i]];
        [[self.imageView_veryGood objectAtIndex:i] setHidden:YES];
    }
    
    
    //問題卡的按鈕
    CGRect rectTemp;//中間的圈圈
    CGRect rectTemp_O;//左上角的O
    CGRect rectTemp_X;//右上角的X
    switch (self.viewNumber) {
        case 0:
        case 1:
            rectTemp=CGRectMake(269, 437, 257, 257);
            rectTemp_O=CGRectMake(30, 88, 154, 147);
            rectTemp_X=CGRectMake(601, 88, 154, 147);
            break;
        case 2:
        case 3:
            rectTemp=CGRectMake(268, 414, 257, 257);
            rectTemp_O=CGRectMake(40, 42, 154, 147);
            rectTemp_X=CGRectMake(599, 42, 154, 147);
            break;
            
        default:
            break;
    }
    
    self.button_questionCard=[[NSMutableArray alloc] initWithCapacity:3];
    //0:中間那個圈圈，1:左上角的O  2:右上角的X
    
    [self addButtonWithImage:@"transparent" andRect:rectTemp andTag:tag_button_questionCard_circle andType:buttonType_questionCard];
    [self addButtonWithImage:@"questionCard_correct_normal" andRect:rectTemp_O andTag:tag_button_questionCard_correct andType:buttonType_questionCard];
    [self addButtonWithImage:@"questionCard_wrong_normal" andRect:rectTemp_X andTag:tag_button_questionCard_wrong andType:buttonType_questionCard];
    
    
    
    
    //問題卡的閃光
    //閃光array的順序是：0:白，1~4:紅黃綠橘
    self.image_questionCard_blink=[[NSMutableArray alloc] initWithCapacity:5];//array一定要初始化，不然很容易產生de不出來的bug
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_W"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_questionCard_1];
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_R"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_questionCard_1];
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_Y"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_questionCard_1];
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_G"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_questionCard_1];
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_O"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_questionCard_1];
    
    
    
    //影片的最後面的背景 + ㄤ仔鑣出現的木頭桌
    self.imageView_movie_background_color=[[UIImageView alloc] initWithImage:[self.backgroundImageList objectAtIndex:1]];
    [self.imageView_movie_background_color setFrame:CGRectMake(0, 0, 768, 1024)];
    self.imageView_movie_background_color.hidden=YES;
    [self.view addSubview:self.imageView_movie_background_color];
    
    
    
    
    
    
    
    
    //播放影片的
    NSString *movieResourcePath;
    NSURL *movieResourceUrl;
    movieResourcePath = [[NSBundle mainBundle] pathForResource:@"sec4" ofType:@"mp4"];//##讀取的影片內容之後應該會再篩選過
    movieResourceUrl = [NSURL fileURLWithPath:movieResourcePath];
    moviePlayer=[[MPMoviePlayerController alloc] initWithContentURL:movieResourceUrl];
    [moviePlayer.view setHidden:YES];
    [self.view addSubview:moviePlayer.view];
    
    
    //影片的thumbnail
    self.movieThumbnailButton = [[UIButton alloc] init];
    [self.movieThumbnailButton setHidden:YES];
    [self.view addSubview:self.movieThumbnailButton];
    
    //音樂的播放器
    
    NSString *soundResourcePath=[[NSBundle mainBundle] pathForResource:@"music_0" ofType:@"mp3"];
    NSURL *soundResourceUrl=[[NSURL alloc] initFileURLWithPath:soundResourcePath];
    musicPlayer=[[AVAudioPlayer alloc] initWithContentsOfURL:soundResourceUrl error:nil];
    [musicPlayer prepareToPlay];
    
    
    //廉幕跟下面那條
    self.imageView_movie_background=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"musicMovie_movieMain"]];
    self.imageView_movie_background.hidden=YES;
    [self.imageView_movie_background setFrame:CGRectMake(0, 0, 768, 1024)];
    [self.view addSubview:self.imageView_movie_background];
    
    
    //歌名
    self.movieLabel = [[UILabel alloc] init];
    [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
    [self.movieLabel setFrame:CGRectMake( 74, 328, 156, 593 )];
    [self.movieLabel setFont:[UIFont fontWithName:@"Heiti TC" size:90.0f]];
    [self.movieLabel setTextColor: [UIColor blackColor]];
    [self.movieLabel setShadowColor:[UIColor lightGrayColor]];
    [self.movieLabel setTextAlignment:NSTextAlignmentCenter];
    [self.movieLabel setShadowOffset:CGSizeMake(3, 3)];
    [self.movieLabel setBackgroundColor:[UIColor clearColor]];
    [self.movieLabel setHidden:YES];
    [self.view addSubview: self.movieLabel];
    
    
    //左右簾幕
    self.imageView_movie_curtainLeft=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"musicMovie_curtainLeft"]];
    self.imageView_movie_curtainLeft.frame=CGRectMake(0, -22, 768, 550);
    self.imageView_movie_curtainLeft.hidden=YES;
    [self.view addSubview:self.imageView_movie_curtainLeft];
    
    
    
    self.imageView_movie_curtainRight=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"musicMovie_curtainRight"]];
    self.imageView_movie_curtainRight.frame=CGRectMake(0, 498, 768, 550);
    self.imageView_movie_curtainRight.hidden=YES;
    [self.view addSubview:self.imageView_movie_curtainRight];
    
    
    
    
    
    
    
    //ㄤ仔鑣基礎真假值設定(##之後要能動態改變
    HPPrimitiveType *primitiveTemp;
    self.pogSheetMapping=[[NSMutableArray alloc] initWithCapacity:6];
    
    //    這邊的Integer表Pog的State, 0:錯誤
    //                             1:正確
    //                             2:已被按過
    
    for(i=0;i<=2;i++){
        primitiveTemp=[[HPPrimitiveType alloc] init];
        primitiveTemp.Integer=1;//正確
        [self.pogSheetMapping addObject:primitiveTemp];
    }
    for(i=3;i<=5;i++){
        primitiveTemp=[[HPPrimitiveType alloc] init];
        primitiveTemp.Integer=0;//錯誤
        [self.pogSheetMapping addObject:primitiveTemp];
    }
    
    
    if(self.viewNumber==3){
        //先加進三張會飛進來的牌
        self.imageView_pogFlyIn=[[NSMutableArray alloc] initWithCapacity:6];
        self.pogSheetFlyIn=[[NSMutableArray alloc] initWithCapacity:6];//
        HPPrimitiveType *primitiveTemp;
        for(i=0;i<=5;i++){
            [self.imageView_pogFlyIn addObject:[[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"transparent"]]]];
            [self.view addSubview:[self.imageView_pogFlyIn objectAtIndex:i]];
            
            primitiveTemp=[[HPPrimitiveType alloc] init];
            primitiveTemp.Integer=999;
            [self.pogSheetFlyIn addObject:primitiveTemp];
        }
        self.imageView_pogQuestion=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pog_question_0"]];//##之後要改成隨機。但總之應該只有viewNumber為3那台有機會使用到這個ImageView
        [self.imageView_pogQuestion setHidden:YES];
        [self.view addSubview:self.imageView_pogQuestion];
    }else{
        //ㄤ仔鑣基礎
        self.button_pogPaper=[[NSMutableArray alloc] initWithCapacity:3];//0,1:兩個鑣 2:原紙
        
        //加鑣進去
        [self addButtonWithImage:[NSString stringWithFormat:@"pog_sheet_%d",self.viewNumber*2] andRect:CGRectMake(202, 139, 391, 387) andTag:tag_button_pogUp andType:buttonType_pogPaper];
        [self addButtonWithImage:[NSString stringWithFormat:@"pog_sheet_%d",(self.viewNumber*2+1)] andRect:CGRectMake(202, 574, 391, 387) andTag:tag_button_pogDown andType:buttonType_pogPaper];
        
        
        [self addButtonWithImage:@"pog_paper_0" andRect:CGRectMake(0, 0, 768, 1024) andTag:tag_button_pogPaper andType:buttonType_pogPaper];
        
        NSArray *pogPaperArray=[NSArray arrayWithObjects:
                                [UIImage imageNamed:@"pog_paper_0"],
                                [UIImage imageNamed:@"pog_paper_1"],
                                [UIImage imageNamed:@"pog_paper_2"],
                                [UIImage imageNamed:@"pog_paper_3"],
                                [UIImage imageNamed:@"pog_paper_4"],
                                nil];
        
        [self blinkArrayAdderWithArray:pogPaperArray andRect:CGRectMake(0, 0, 768, 1024) andType:blinkAnimationType_pogPaperTorn];
        
        
        
    }
    
    
    
    //問題卡上面蓋的的黑色(頗萬用)
    self.questionCard_black=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pureBlack"]];
    self.questionCard_black.frame=CGRectMake(0, 0, 768, 1024);
    self.questionCard_black.alpha=0.4f;
    [self.view addSubview:self.questionCard_black];
    [self.questionCard_black setHidden:YES];
    
    
    self.button_toolbar_number=[[NSMutableArray alloc] initWithCapacity:7];
    self.button_toolbar_function=[[NSMutableArray alloc] initWithCapacity:5];
    if(self.viewNumber==0){//右上的機器：工具列
        
        //lay上半部
        UIImageView *backgroundToolbar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tool_bar__01"]];
        backgroundToolbar.frame=CGRectMake(0,0, 768, 48);
        [self.view addSubview:backgroundToolbar];
        
        //button：地圖
        [self addButtonWithImage:@"back_to_map" andRect:CGRectMake(561,1, 97, 44) andTag:tag_button_toolbar_0_map andType:buttonType_toolbar_function];
        //button：燈光提示
        [self addButtonWithImage:@"light_hint_on" andRect:CGRectMake(449,1, 97, 44) andTag:tag_button_toolbar_1_light andType:buttonType_toolbar_function];
        //button：播放
        [self addButtonWithImage:@"play_and_pause" andRect:CGRectMake(338,1, 97, 44) andTag:tag_button_toolbar_2_play andType:buttonType_toolbar_function];
        //button：音效
        [self addButtonWithImage:@"music_press" andRect:CGRectMake(229,1, 97, 44) andTag:tag_button_toolbar_3_music andType:buttonType_toolbar_function];
        //button：上一頁
        [self addButtonWithImage:@"backward" andRect:CGRectMake(119,1, 97, 44) andTag:tag_button_toolbar_4_backward andType:buttonType_toolbar_function];
    }else if(self.viewNumber==1){//左上：數字
        
        //lay上半部
        UIImageView *backgroundToolbar = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"tool_bar__01"]];
        backgroundToolbar.frame=CGRectMake(0,0, 768, 48);
        [self.view addSubview:backgroundToolbar];
        
        int i;
        //加一個緩衝的進去，當做第0個元素
        UIButton *button_toolbar_number_temp = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.button_toolbar_number addObject:button_toolbar_number_temp];
        CGRect numberRectTemp;
        
        for (i=1;i<=6;i++){
            switch(i){
                case 1:
                    numberRectTemp=CGRectMake(609,1, 97, 44);
                    break;
                case 2:
                    numberRectTemp=CGRectMake(498,1, 97, 44);
                    break;
                case 3:
                    numberRectTemp=CGRectMake(390,1, 97, 44);
                    break;
                case 4:
                    numberRectTemp=CGRectMake(280,1, 97, 44);
                    break;
                case 5:
                    numberRectTemp=CGRectMake(170,1, 97, 44);
                    break;
                case 6:
                    numberRectTemp=CGRectMake(60,1, 97, 44);
                    break;
                default:
                    break;
            }
            [self addButtonWithImage:[NSString stringWithFormat:@"button_%d_dark",i] andRect:numberRectTemp andTag:(tag_button_toolbar_number_1+i-1) andType:buttonType_toolbar_number];
        }
    }
    
    
    //TEST
    [self addButtonWithImage:@"button_1_dark" andRect:CGRectMake(609,900, 97, 44) andTag:tag_button_test1 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_2_dark" andRect:CGRectMake(498,900, 97, 44) andTag:tag_button_test2 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_3_dark" andRect:CGRectMake(390,900, 97, 44) andTag:tag_button_test3 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_4_dark" andRect:CGRectMake(280,900, 97, 44) andTag:tag_button_test4 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_5_dark" andRect:CGRectMake(170,900, 97, 44) andTag:tag_button_test5 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_6_dark" andRect:CGRectMake(60,900, 97, 44) andTag:tag_button_test6 andType:buttonType_TEST];
    //TESTEND
    
    //load最後，才進行棋子擺放
    [self playerHandoff];
    
    viewDidLoadHandoff = NO;
    
    
}

-(void)movieButtonPressed{
    [self showMoiveAndMusic:movieAndMusicState_movieInitialization andSelectedView:self.viewNumber];
    //$$廣播給其他人，只有selectedView是self.viewNumber
}

-(void)musicButtonPressed{
    [self showMoiveAndMusic:movieAndMusicState_musicInitialization andSelectedView:self.viewNumber];
    //$$廣播給其他人，只有selectedView是self.viewNumber
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag//音樂停止時
{
    NSLog(@"fuckyou");
}
-(void)stopAudio{
    self.toolbarPlayerState=playerStateType_prepared;
    if(self.viewNumber==0){
        UIButton *buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_2_play-tag_button_toolbar_Base-1)];
        [buttonTemp setBackgroundImage:[UIImage imageNamed:@"play_and_pause"] forState:UIControlStateNormal];
    }
}
-(void)showMoiveAndMusic:(movieAndMusicState)stateInput andSelectedView:(int)selectedViewNumber{
    
    NSString *movieResourcePath;//switch-case裡面沒辦法初始化變數，因為程式會不確定這個東西到底有沒有辦法被declared
    NSURL *movieResourceUrl;
    
    NSString *soundResourcePath;
    NSURL *soundResourceUrl;
    
    switch (stateInput) {
        case movieAndMusicState_movieSelect://第一次初始化，給大家選
            self.movieOrMusicNow=movieOrMusic_movie;//告訴系統現在是進入影片模式->讓播放鍵可以知道要放影片還是音樂
            //##沒做廉幕拉開
            
            //設定背景、文字等
            
            //顯示廉幕跟文字
            switch (self.viewNumber) {//##第一次出現的名稱
                case 0:
                    [self.movieLabel setText:@"快樂的出航航"];
                    break;
                case 1:
                    [self.movieLabel setText:@"淚的小雨"];
                    break;
                case 2:
                    [self.movieLabel setText:@"安平追想曲"];
                    break;
                case 3:
                    [self.movieLabel setText:@"舞伴淚影"];
                    break;
                default:
                    break;
            }
            
            [self.imageView_movie_background_color setHidden:NO];
            [self backgroundColorReset:1];
            [self.imageView_movie_background setImage:[UIImage imageNamed:@"musicMovie_movieMain"]];
            [self.imageView_movie_background setHidden:NO];
            [self.movieLabel setHidden:NO];
            
            
            //影片讀出
            movieResourcePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"movie_%d",self.viewNumber] ofType:@"mp4"];//##讀取的影片內容之後應該會再篩選過
            movieResourceUrl = [NSURL fileURLWithPath:movieResourcePath];
            [moviePlayer setContentURL:movieResourceUrl];
            [moviePlayer setShouldAutoplay:NO];
            
            
            
            if(self.whoseTurn==playerColor_red||self.whoseTurn==playerColor_yellow){//##之後frame要在微調
                
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0))];
                
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [self.movieLabel setFrame:CGRectMake( 74, 328, 156, 593 )];
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(226, 149, 542, 725)];
                
                
            }else if(self.whoseTurn==playerColor_green||self.whoseTurn==playerColor_orange){
                
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0))];
                
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieLabel setFrame:CGRectMake( 540, 115, 156, 593 )];
                
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(0, 149, 542, 725)];
            }
            
            
            [self.imageView_movie_background setFrame:CGRectMake(0, 0, 768, 1024)];
            
            
            
            //按鈕式圖片
            
            [self.movieThumbnailButton setBackgroundImage:[moviePlayer thumbnailImageAtTime:10.0
                                                                                 timeOption:MPMovieTimeOptionNearestKeyFrame] forState:UIControlStateNormal];
            [self.movieThumbnailButton addTarget:self action:@selector(movieButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            
            [self.movieThumbnailButton setHidden:NO];
            
            
            
            break;
            
        case movieAndMusicState_movieInitialization:
            movieResourcePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"movie_%d",selectedViewNumber] ofType:@"mp4"];//##讀取的影片內容之後應該會再篩選過
            self.movieMusicSelected=selectedViewNumber;//把「選到哪台」存起來
            movieResourceUrl = [NSURL fileURLWithPath:movieResourcePath];
            [moviePlayer setContentURL:movieResourceUrl];
            [moviePlayer setShouldAutoplay:NO];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAudio)
                                                         name:MPMoviePlayerPlaybackDidFinishNotification
                                                       object:moviePlayer];
            [moviePlayer setControlStyle:MPMovieControlStyleNone];
            
            //顯示廉幕跟文字
            switch (selectedViewNumber) {//##現在viewnumber跟選到的影片意思一樣，之後要再做一次mapping
                case 0:
                    [self.movieLabel setText:@"快樂的出航"];
                    break;
                case 1:
                    [self.movieLabel setText:@"淚的小雨"];
                    break;
                case 2:
                    [self.movieLabel setText:@"安平追想曲"];
                    break;
                case 3:
                    [self.movieLabel setText:@"舞伴淚影"];
                    break;
                default:
                    break;
            }
            
            if(self.viewNumber==1||self.viewNumber==2){//在左邊的情況
                
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0))];
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [self.movieLabel setFrame:CGRectMake( 74, 328, 156, 593 )];
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(226, 149, 542, 725)];
                
                //                [moviePlayer.view setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                //                [moviePlayer.view setFrame:  CGRectMake(226, 149, 542, 725)];
                
            }else if(self.viewNumber==0||self.viewNumber==3){
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0))];
                
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieLabel setFrame:CGRectMake( 540, 115, 156, 593 )];
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(0, 149, 542, 725)];
                
                //                [moviePlayer.view setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                //                [moviePlayer.view setFrame:  CGRectMake(0, 149, 542, 725)];
            }
            [self.imageView_movie_background setFrame:CGRectMake(0, 0, 768, 1024)];
            self.toolbarPlayerState=playerStateType_prepared;
            break;
            
            
        case movieAndMusicState_moviePlay:
            self.gameState=gameState_movieDisplayPlaying;
            [self.movieThumbnailButton setHidden:YES];
            [self.imageView_movie_background setHidden:YES];
            [self.movieLabel setHidden:YES];
            
            //顯示影片
            
            if(self.viewNumber==1||self.viewNumber==2){//在左邊的情況
                
                [moviePlayer.view setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [moviePlayer.view setFrame:  CGRectMake(0, 0, 768, 1024)];
                
            }else if(self.viewNumber==0||self.viewNumber==3){
                [moviePlayer.view setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [moviePlayer.view setFrame:  CGRectMake(0, 0, 768, 1024)];
            }
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopAudio)
                                                         name:MPMoviePlayerPlaybackDidFinishNotification
                                                       object:moviePlayer];
            
            if(self.viewNumber==0){
                UIButton *buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_2_play-tag_button_toolbar_Base-1)];
                [buttonTemp setBackgroundImage:[UIImage imageNamed:@"play_press"] forState:UIControlStateNormal];
            }
            [moviePlayer.view setHidden:NO];
            [moviePlayer play];
            self.toolbarPlayerState=playerStateType_play;
            
            break;
        case movieAndMusicState_movieStop:
            self.toolbarPlayerState=playerStateType_none;
            [moviePlayer stop];
            [moviePlayer.view setHidden:YES];
            [self.imageView_movie_background_color setHidden:YES];
            
            
            break;
            
            
            
        case movieAndMusicState_musicSelect://音樂初始化，給大家選
            self.movieOrMusicNow=movieOrMusic_music;
            self.gameState=gameState_musicDisplayInitialization;
            //##沒做廉幕拉開
            
            //設定背景、文字等
            
            //顯示廉幕跟文字
            switch (self.viewNumber) {//##第一次出現的名稱
                case 0:
                    [self.movieLabel setText:@"夢のきざはし"];
                    break;
                case 1:
                    [self.movieLabel setText:@"ゆきもよ"];
                    break;
                case 2:
                    [self.movieLabel setText:@"Natsukage"];
                    break;
                case 3:
                    [self.movieLabel setText:@"Laura theme"];
                    break;
                default:
                    break;
            }
            
            [self.imageView_movie_background_color setHidden:NO];
            [self backgroundColorReset:1];
            [self.imageView_movie_background setImage:[UIImage imageNamed:@"musicMovie_musicMain"]];
            [self.imageView_movie_background setHidden:NO];
            [self.movieLabel setHidden:NO];
            
            
            
            if(self.whoseTurn==playerColor_red||self.whoseTurn==playerColor_yellow){//##之後frame要在微調
                
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0))];
                
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [self.movieLabel setFrame:CGRectMake( 74, 328, 156, 593 )];
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(226, 149, 542, 725)];
                
                
            }else if(self.whoseTurn==playerColor_green||self.whoseTurn==playerColor_orange){
                
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0))];
                
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieLabel setFrame:CGRectMake( 540, 115, 156, 593 )];
                
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(0, 149, 542, 725)];
            }
            
            
            [self.imageView_movie_background setFrame:CGRectMake(0, 0, 768, 1024)];
            
            
            
            //按鈕式圖片
            
            [self.movieThumbnailButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"musicPhoto_%d",self.viewNumber]] forState:UIControlStateNormal];//##這邊應該是要填入音樂的圖
            
            
            [self.movieThumbnailButton addTarget:self action:@selector(musicButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            
            [self.movieThumbnailButton setHidden:NO];
            
            
            
            break;
            
        case movieAndMusicState_musicInitialization:
            self.movieMusicSelected=selectedViewNumber;//把「選到哪台」存起來
            //顯示廉幕跟文字
            switch (self.movieMusicSelected) {//##第一次出現的名稱
                case 0:
                    [self.movieLabel setText:@"夢のきざはし"];
                    break;
                case 1:
                    [self.movieLabel setText:@"ゆきもよ"];
                    break;
                case 2:
                    [self.movieLabel setText:@"Natsukage"];
                    break;
                case 3:
                    [self.movieLabel setText:@"Laura theme"];
                    break;
                default:
                    break;
            }
            
            if(self.viewNumber==1||self.viewNumber==2){//在左邊的情況
                
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(0.0))];
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [self.movieLabel setFrame:CGRectMake( 74, 328, 156, 593 )];
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(226, 149, 542, 725)];
                
            }else if(self.viewNumber==0||self.viewNumber==3){
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0))];
                
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieLabel setFrame:CGRectMake( 540, 115, 156, 593 )];
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(0, 149, 542, 725)];
                
            }
            [self.imageView_movie_background setFrame:CGRectMake(0, 0, 768, 1024)];
            self.toolbarPlayerState=playerStateType_prepared;
            
            [self.movieThumbnailButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"musicPhoto_%d",self.movieMusicSelected]] forState:UIControlStateNormal];
            
            break;
            
        case movieAndMusicState_musicPlay:
            
            self.gameState=gameState_musicDisplayPlaying;
            [self.imageView_movie_background setHidden:YES];
            [self.movieLabel setHidden:YES];
            //TEST
            NSLog(@"SVN:%d",self.movieMusicSelected);
            //TESTEND
            soundResourcePath=[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"music_%d",self.movieMusicSelected] ofType:@"mp3"];
            soundResourceUrl=[[NSURL alloc] initFileURLWithPath:soundResourcePath];
            musicPlayer=[[AVAudioPlayer alloc] initWithContentsOfURL:soundResourceUrl error:nil];
            [musicPlayer prepareToPlay];
            [musicPlayer play];
            
            //顯示影片
            
            if(self.viewNumber==1||self.viewNumber==2){//在左邊的情況
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(0, 0, 768, 1024)];
                
            }else if(self.viewNumber==0||self.viewNumber==3){
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(0, 0, 768, 1024)];
            }
            
            
            if(self.viewNumber==0){
                UIButton *buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_2_play-tag_button_toolbar_Base-1)];
                [buttonTemp setBackgroundImage:[UIImage imageNamed:@"play_press"] forState:UIControlStateNormal];
            }
            self.toolbarPlayerState=playerStateType_play;
            
            break;
            
        case movieAndMusicState_musicStop:
            self.toolbarPlayerState=playerStateType_none;
            [musicPlayer stop];
            [self.imageView_movie_background_color setHidden:YES];
            [self.movieThumbnailButton setHidden:YES];
            
            
            break;
            
            
        default:
            break;
    }
    
}



- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
    const char *incomingPacket = (const char*)[data bytes];
    char messageType = incomingPacket[0];
    switch (messageType) {
        case gkMessageHandoffInfo:{
            [self playerHandoffFromRemote];
            NSLog(@"get handoff");
            break;
        }
        case gkMessageNumHitInfo:{
            numHitInfoMessage = *(NumHitInfo *)(incomingPacket + 1);
            if (self.gameState==gameState_throwDice) {
                self.stepToGo = numHitInfoMessage.nowPressedNumberTrs;
                [self stepToGoDisplay];
                [self resetAllIconInState:2 andFocusedPlayer:self.whoseTurn];
            }
            break;
        }
        case gkMessageHitPhotoInfo:{
            hitPhotoFromRemote = YES;
            hitPhotoInfoMessage = *(HitPhotoInfo *)(incomingPacket +1);
            [self buttonHit_photo:0];
            break;
        }
        case gkMessageToolbarHitInfo:{
            toolbarHitInfoMessage = *(ToolbarHitInfo *)(incomingPacket + 1);
            [self buttonHit_toolbar_functionFromRemote];
            NSLog(@"toolbar");
            break;
        }
        case gkMessageQuestionCardHit:{
            questionCardHitInfoMessage = *(QuestionCardHitInfo *)(incomingPacket + 1);
            self.questionCardSelectedNumber = questionCardHitInfoMessage.questionCardSelectedNumberTrs;
            [NSTimer scheduledTimerWithTimeInterval:1
                                             target:self
                                           selector:@selector(timerEvent:)
                                           userInfo:nil
                                            repeats:NO];
            break;
        }
           
        case gkMessageQuestionCardRight:
            sleep(3);
            [self showChance:2 andTarget:UNIMPORTANT];
            break;
            
        case gkMessageQuestionCardWrong:
            [self showChance:2 andTarget:UNIMPORTANT];
            break;
        
            
        default:{
            NSString* msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"%@",msg);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg
                                                            message:msg
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            break;
        }
    }
}

- (void) sendData:(NSData*)data useSession:(GKSession *)session
{
    [session sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
	NSString* stateDesc;
	if (state == GKPeerStateAvailable) stateDesc = @"GKPeerStateAvailable";
	else if (state == GKPeerStateUnavailable) stateDesc = @"GKPeerStateUnavailable";
	else if (state == GKPeerStateConnected) stateDesc =	@"GKPeerStateConnected";
	else if (state == GKPeerStateDisconnected) stateDesc = @"GKPeerStateDisconnected";
	else if (state == GKPeerStateConnecting) stateDesc = @"GKPeerStateConnecting";
    NSLog(@"%s|%@|%@", __PRETTY_FUNCTION__, peerID, stateDesc);
	
	switch (state) {
		case GKPeerStateAvailable:
			NSLog(@"connecting to %@ ...", [session displayNameForPeer:peerID]);
			[session connectToPeer:peerID withTimeout:10];
			break;
			
		case GKPeerStateConnected:{
            //            NSMutableData *data = [NSMutableData dataWithCapacity:1 + sizeof(int)];
            //            messageType = gkIsServer;
            //            [data appendBytes:&messageType length:1];
            //            srand((unsigned)time(NULL));
            //            intToBeCompared = rand();
            //            [data appendBytes:&intToBeCompared length:sizeof(int)];
            //            [self.gkSession sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
            
//            if(![peers containsObject:peerID])
//                [peers addObject:peerID];
//            
//            numPeers = [peers count] + 1;           //add self
//            
//            self.gkPeerID = peerID;
//            appDelegate.gkSession = self.gkSession;
//            NSLog(@"numPeers %d", numPeers);
			break;
        }
			
		case GKPeerStateDisconnected:
			session = nil;
		default:
			break;
	}
	NSLog(@"---------------");
}

- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID
{
	NSLog(@"%s|%@", __PRETTY_FUNCTION__, peerID);
	NSError* error = nil;
	[session acceptConnectionFromPeer:peerID error:&error];
	if (error) {
		NSLog(@"%@", error);
	}
}

- (IBAction)buttonHit_TEST:(id)sender
{
    NSLog(@"state now %d",self.gameState);
}


@end
