

#import "HPMapViewController.h"


#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

@interface HPMapViewController ()

@end

@implementation HPMapViewController

//button的listener
- (IBAction)buttonHit_toolbar_function:(id)sender{
    UIButton *inputButton=(UIButton *)sender;
    NSLog(@"%d",inputButton.tag);
    
    UIButton *buttonTemp;
    
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
            if(!self.mapLongPressActivated){//^^正常按地圖
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
                    case gameState_pogDisable:
                    case gameState_pogAvaliable:
                        
                        [self showPogAndSelectedView:EXIT];
                        [self playerHandoff];//換人了
                        break;
                    default:
                        break;
                }
            }else{//結束
                NSLog(@"END");
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
- (IBAction)buttonHit_toolbar_number:(id)sender{
    UIButton *inputButton=(UIButton *)sender;
    NSLog(@"%d",inputButton.tag);
    
    UIButton *buttonTemp;
    int i;
    
    [self button_toolbar_darkener];
    
    
    int nowPressedNumber=(inputButton.tag-tag_button_toolbar_number_1+1);
    if (self.gameState==gameState_throwDice) {
        buttonTemp=[self.button_toolbar_number objectAtIndex:nowPressedNumber];
        [buttonTemp setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"button_%d_light",nowPressedNumber]] forState:UIControlStateNormal];
        //重置走x步
        self.stepToGo=nowPressedNumber;
        [self stepToGoDisplay];
        
        HPPlayer *presentPlayer=[self.playerList objectAtIndex:self.whoseTurn];
        [self resetAllIconInState:2 andFocusedPlayer:self.whoseTurn];
        
    }
    
}
-(void)button_toolbar_darkener{
    UIButton *buttonTemp;
    int i;
    
    //先把所有的按鈕都變暗，之後把按到的變亮
    for(i=1;i<=6;i++){
        buttonTemp=[self.button_toolbar_number objectAtIndex:i];
        [buttonTemp setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"button_%d_dark",i]] forState:UIControlStateNormal];
    }
    
}

- (IBAction)buttonHit_photo:(id)sender{
    UIButton *inputButton=(UIButton *)sender;
    NSLog(@"%d",inputButton.tag);
    
    //現在按到的photo，在0~11的position裡面的位置
    int globalPressedPosition=inputButton.tag-tag_button_photo_0+self.viewNumber*3;
    
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
                
                //這邊的運作邏輯是，會先給state，並呼叫timer，來讓進入其他狀態潛前有一段緩衝時間。
                
                switch (presentTurnPlayer.playerPosition) {//##還有一堆state沒做
                    case 1://影片
//                      呼叫movie
//                        self.delayTimerEvent=delayTimerEventType_video  ;
//                        self.gameState=gameState_movieDisplayInitialization;
//                        break;
                        
                    case 4://音樂
//                      呼叫music
//                        self.delayTimerEvent=delayTimerEventType_music;
//                        self.gameState=gameState_musicDisplayInitialization;
//                        break;
                        
                    case 7://機會
//                      呼叫chance
//                        self.delayTimerEvent=delayTimerEventType_chance;
//                        self.gameState=gameState_chanceDisplayInitialization;
//                        break;
                    case 10://遊戲
                        
//                        self.gameState=gameState_pogInitialization;
//                        self.delayTimerEvent=delayTimerEventType_game;
//                        break;

                        
                        self.gameState=gameState_pogInitialization;
                        self.delayTimerEvent=delayTimerEventType_game;
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
    }else if(typeInput==2){
        [self.imageView_movie_background_color setImage:[self.backgroundImageList objectAtIndex:playerColor_ForTable]];
    }
    
}

//統一管控所有跟blink有關的動畫
-(void)blinkAnimationFor:(blinkAnimationType)blinkAnimationTypeInput andState:(blinkAnimationState)blinkAnimationStateInput{
    int i,j;//expected expression:在switch中不太能宣告變數不然會爛掉。
    CGRect blinkFrame;//要blink的位置
    HPPrimitiveType *primitiveTemp;
    //足跡的blink
    HPPlayer *presentPlayer=[self.playerList objectAtIndex:self.whoseTurn];
    switch (blinkAnimationTypeInput) {
        case blinkAnimationType_icon:

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
                    self.image_icon_blink.frame=CGRectMake(388,686, 231, 228);
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
            
            break;
            
            
        case blinkAnimationType_photo:

            for(j=0;j<12;j++){//就全關吧，我也懶得算了
                [[self.image_photo_blink objectAtIndex:j] stopAnimating];
            }
            if(blinkAnimationStateInput==blinkAnimationState_on){
                int k;
                if(self.gameState==gameState_moveForward){
                    if(self.toolbarLightOn){//全部燈光提示都要有的
                        for(j=presentPlayer.playerPosition+1;j<=presentPlayer.playerPosition+self.stepToGo;j++){//再把要的打開
                            k=j%12;//已經走一圈的狀況要重來
                            if(k>=(self.viewNumber*3)&&k<(self.viewNumber+1)*3){//在可視範圍中
                                [[self.image_photo_blink objectAtIndex:(k%3+self.whoseTurn*3)] startAnimating];//顏色正確的燈閃出來
                            }
                        }
                    }else{//只要下一步提示的
                        if(presentPlayer.playerPosition<=presentPlayer.playerPosition+self.stepToGo){
                            if((presentPlayer.playerPosition)>=(self.viewNumber*3)&&(presentPlayer.playerPosition)<(self.viewNumber+1)*3){//在可視範圍中
                                [[self.image_photo_blink objectAtIndex:((presentPlayer.playerPosition)%3+self.whoseTurn*3)] startAnimating];//顏色正確的燈閃出來
                            }
                        }
                    }
                }
            }

            break;
            
            
        //問題卡初始化，所有都變成白色
        case blinkAnimationType_circleWithoutColor:
            //%%
            
            if(blinkAnimationStateInput==blinkAnimationState_movieMusicLeftUp){//這邊先確定位置，由傳入的參數控制
                [self blinkImageCirclePlace:blinkImageCirclePlaceStateMovieMusicLeftUp];
                NSLog(@"這");
                [[self.image_questionCard_blink objectAtIndex:0] startAnimating];
            }else if(blinkAnimationStateInput==blinkAnimationState_movieMusicRightDown){
                [self blinkImageCirclePlace:blinkImageCirclePlaceStateMovieMusicRightDown];
                [[self.image_questionCard_blink objectAtIndex:0] startAnimating];
            }else{
                [self blinkImageCirclePlace:blinkImageCirclePlaceStateQuestionCard];//只有questionCard才要額外辨識要不要量起來
                primitiveTemp=[self.questionCardSelected objectAtIndex:self.viewNumber];
                if(!primitiveTemp.Boolean){//如果自己沒被按過了，才顯示白圈
                    [[self.image_questionCard_blink objectAtIndex:0] startAnimating];
                }
            }
            

            
            break;
            
            
        case blinkAnimationType_circleWithColor:
            //blinkAnimationState_on:只剩一個顏色再閃，其他都暗掉,
            //blinkAnimationState_off: 全部都暗掉
            
            //%%改成4
            for(i=0;i<=4;i++){//全關
                [[self.image_questionCard_blink objectAtIndex:i] stopAnimating];
            }
            //這個管控在buttonHit_questionCard就做掉了，所以這邊只要直接閃或停就好了
            if(blinkAnimationStateInput==blinkAnimationState_on){
                [[self.image_questionCard_blink objectAtIndex:self.whoseTurn+1] startAnimating];
            }else if(blinkAnimationStateInput==blinkAnimationState_off){
                
            }
            
            break;
            
        //%%
        case blinkAnimationType_pog:
            if(blinkAnimationStateInput==blinkAnimationState_on){//要開亮ㄤ仔標 - 依照現在的state
                for(i=0;i<=1;i++){
                    primitiveTemp=[self.pogSheetMapping objectAtIndex:(i+self.viewNumber*2)];
                    if(primitiveTemp.Integer==2){
                        [[self.imageView_blink_pog objectAtIndex:(i)] setHidden:YES];
                        [[self.imageView_blink_pog objectAtIndex:(i)] stopAnimating];
                    }else{
                        [[self.imageView_blink_pog objectAtIndex:(i)] setHidden:NO];
                        [[self.imageView_blink_pog objectAtIndex:(i)] startAnimating];
                    }

                }
            }else{//全部關暗
                for(i=0;i<=1;i++){
                    [[self.imageView_blink_pog objectAtIndex:(i)] setHidden:YES];
                    [[self.imageView_blink_pog objectAtIndex:(i)] stopAnimating];
                }
            }
            
            default:
            break;
    }
    
}
//看閃閃閃的圈圈要放在哪裡
-(void)blinkImageCirclePlace:(blinkImageCirclePlaceState)stateInput{
    //blinkImageCirclePlaceStateQuestionCard:問題卡的圈圈
    //blinkImageCirclePlaceStateMovieMusicLeftUp:影片、音樂的左上角
    //blinkImageCirclePlaceStateMovieMusicRightDown:影片、音樂的右上角
    
    CGRect rectTemp;
    int i;
    switch (stateInput) {
        case blinkImageCirclePlaceStateQuestionCard:
            switch (self.viewNumber) {
                case 0:
                case 1:
                    rectTemp=CGRectMake(269, 437, 257, 257);
                    break;
                case 2:
                case 3:
                    rectTemp=CGRectMake(268, 414, 257, 257);
                    break;
                default:
                    break;
            }
            break;
        case blinkImageCirclePlaceStateMovieMusicLeftUp:
            rectTemp=CGRectMake(23, 78, 257, 257);
            break;
        case blinkImageCirclePlaceStateMovieMusicRightDown:
            rectTemp=CGRectMake(487, 687, 257, 257);
            break;
        default:
            break;
    }
    for(i=0;i<=4;i++){//全關
        [[self.image_questionCard_blink objectAtIndex:i] setFrame:rectTemp];
    }

    
    
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
        case blinkAnimationType_circleWithoutColor:
            [self.image_questionCard_blink addObject:image_blink_animation];
            break;
        case blinkAnimationType_veryGood:
            [self.imageView_veryGood addObject:image_blink_animation];
            break;
        case blinkAnimationType_pogPaperTorn:
            image_blink_animation.animationRepeatCount = 1;//只播一次
            self.imageView_pogPaperTorn=image_blink_animation;
            break;
        case blinkAnimationType_pog:
            [self.imageView_blink_pog addObject:image_blink_animation];
            break;
        case blinkAnimationType_movieMusicNormal:
        default:
            break;
    }
    
    [self.view addSubview:image_blink_animation];
}


//換新使用者
-(void)playerHandoff{
    //##之後影片那些也還要做初始化
    self.overallRound+=1;
    
    NSLog(@"whose?前,%d",self.whoseTurn);
    self.whoseTurn=(self.whoseTurn+1)%self.playerNumber;
    NSLog(@"whose?後,%d",self.whoseTurn);
    self.gameState=gameState_throwDice;
    [self stepToGoDisplay];
    [self blinkAnimationFor:blinkAnimationType_photo andState:blinkAnimationState_off];//把全部的地圖燈都關掉
    if(self.viewNumber==0){//把播放關掉
        UIButton *buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_2_play-tag_button_toolbar_Base-1)];
        [buttonTemp setBackgroundImage:[UIImage imageNamed:@"play_and_pause"] forState:UIControlStateNormal];
    }
    
    if(self.viewNumber==1){
        [self button_toolbar_darkener];
    }
    self.stepToGo=0;
    [self backgroundColorReset:0];
    [self resetAllIconInState:3 andFocusedPlayer:self.whoseTurn];//先變成箭頭來提醒現在的使用者
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
        }else{
            //            if(self.whoseTurn!=playerColor_blue){//正常情況，顯示水平的
            [self.button_stepIndicator setImage:[self.stepImageList objectAtIndex:6]];
            //            }else{//如果是藍色的狀況，就要顯示成垂直的
            //                [self.button_stepIndicator setImage:[self.stepImageList objectAtIndex:13]];
            //            }
        }
    }else if(self.gameState==gameState_moveForward){//顯示步數
        [self blinkAnimationFor:blinkAnimationType_photo andState:blinkAnimationState_on];
        //要position有在可視範圍內才顯示
        if(nowPlayer.playerPosition>=(self.viewNumber+1)*3||nowPlayer.playerPosition<self.viewNumber*3||self.stepToGo==0){
            NSLog(@"我在這");
            [self.button_stepIndicator setImage:[UIImage imageNamed:@"transparent"]];
        }else{
            //            if(self.whoseTurn!=playerColor_blue){//正常情況，顯示水平的
            [self.button_stepIndicator setImage:[self.stepImageList objectAtIndex:(self.stepToGo-1)]];
            //            }else{//如果是藍色的狀況，就要顯示成垂直的
            //                [self.button_stepIndicator setImage:[self.stepImageList objectAtIndex:(self.stepToGo+7-1)]];
            //            }
        }
    }
    
}

-(void)showPhoto:(NSInteger)stateInput{
    //state EXIT:不顯示
    //          1:顯示
    
    
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
        
        //^^
        HPPlayer *presentPlayer=[self.playerList objectAtIndex:self.whoseTurn];
        HPPrimitiveType *prmitiveTypeTemp=[self.placePositionMapping objectAtIndex:presentPlayer.playerPosition];
        NSLog(@"hoho,%d,%d",self.whoseTurn,prmitiveTypeTemp.Integer);
        [self.albumFrame setImage:self.albumFrame_horizontal];
        [self.albumPhoto setImage:[[self.imageLoadedList objectAtIndex:self.whoseTurn] objectAtIndex:prmitiveTypeTemp.Integer]];

        
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

- (IBAction)buttonHit_questionCard:(id)sender{
    UIButton *inputButton=(UIButton *)sender;
    NSLog(@"%d",inputButton.tag);
    switch (self.gameState) {
        case gameState_chanceDisplayOutside://母牌要進入子牌
            if(inputButton.tag==tag_button_questionCard_circle){//自己被選到才要閃
                
                
                //把自己的那個圓形的燈開亮一下
                [self blinkAnimationFor:blinkAnimationType_circleWithColor andState:blinkAnimationState_on];
                
                //$$下行廣播給所有人聽，改他們的self.questionCardSelectedNumber為此台的self.viewNumber
                self.questionCardSelectedNumber=self.viewNumber;//現在是自己被選到
                
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
                
                //^^
                UIImageView *imTemp= [self.imageView_veryGood objectAtIndex:0];
                [imTemp setImage:[self.image_veryGood_background objectAtIndex:self.whoseTurn]];
                [[self.imageView_veryGood objectAtIndex:0] setHidden:NO];
                [[self.imageView_veryGood objectAtIndex:1] setHidden:NO];

                
                //顯示你好棒
                self.veryGoodAnimationFrameNumber=0;
                [NSTimer scheduledTimerWithTimeInterval:1 //要用timer的話就用這行
                                                 target:self
                                               selector:@selector(customAnimation:)
                                               userInfo:nil
                                                repeats:YES];
                
                //TESTEND
                
                HPPrimitiveType *ptTemp=[self.questionCardSelected objectAtIndex:self.viewNumber];
                ptTemp.Boolean=YES;//答對之後黑掉
                
                
                for(i=1;i<=2;i++){//這行寫的有點爛，總之是為了把兩個按鈕拔掉，但是寫了第二次
                    [[self.button_questionCard objectAtIndex:i] setHidden:YES];
                }
                
                self.delayTimerEvent=delayTimerEventType_chanceVeryGood;
                [NSTimer scheduledTimerWithTimeInterval:10 //要用timer的話就用這行
                                                 target:self
                                               selector:@selector(timerEvent:)
                                               userInfo:nil
                                                repeats:NO];
                
            }else if(inputButton.tag==tag_button_questionCard_wrong){//答錯了
                //$$廣播給所有人
                [self showChance:2 andTarget:UNIMPORTANT];
            }
            break;
        default:
            break;
    }
    
}
-(void)showChance:(NSInteger)stateInput andTarget:(int)targetViewNumber{//Chance進來了,targetViewNumber是按到哪張子牌
    //state EXIT:不顯示
    //      1:初始化(第一次顯示母牌)
    //      2:正常顯示母牌(第二次以後)
    //      3:顯示子牌
    int i;
    HPPrimitiveType *boolTemp;
    switch (stateInput) {
        case EXIT:
            [self.questionCard setHidden:YES];
            [self.questionCard_black setHidden:YES];
            for(i=0;i<=2;i++){
                [[self.button_questionCard objectAtIndex:i] setHidden:YES];
            }
            [self blinkAnimationFor:blinkAnimationType_circleWithColor andState:blinkAnimationState_off];//把全部關掉
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
            
            [self blinkAnimationFor:blinkAnimationType_circleWithoutColor andState:UNIMPORTANT];//把全部開亮
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
                [self blinkAnimationFor:blinkAnimationType_circleWithoutColor andState:UNIMPORTANT];//把全部開亮
            }
            self.gameState=gameState_chanceDisplayOutside;
            break;
            
        case 3://有人要顯示子牌
            boolTemp=[self.questionCardSelected objectAtIndex:self.viewNumber];
            if(!boolTemp.Boolean){//若自己已經被按過了：就不用管了
                [self blinkAnimationFor:blinkAnimationType_circleWithColor andState:blinkAnimationState_off];//把全部關掉
                if(targetViewNumber==self.viewNumber){//如果是自己被按到的話才做事情
                    [self.questionCard setImage:[self.image_questionCard objectAtIndex:self.viewNumber+1]];//##這邊之後應該要用亂數
                    //                                                                                      但之前寫的也懶得改了...
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

-(void)buttonHit_mapLong{
    NSLog(@"YOU SOB");
    self.mapLongPressActivated=YES;
    UIButton *buttonTemp;
    buttonTemp=[self.button_toolbar_function objectAtIndex:0];//把button的圖換成結束
    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"end_"] forState:UIControlStateNormal];
    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"end_"] forState:UIControlEventTouchDown];
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
                case tag_button_toolbar_0_map:{
                    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"back_to_map_press"] forState:UIControlEventTouchDown];
                    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                                          initWithTarget:self action:@selector(buttonHit_mapLong)];
                    lpgr.minimumPressDuration = 1.0; //seconds
                    [buttonTemp addGestureRecognizer:lpgr];

                    break;
                }
                case tag_button_toolbar_4_backward:
                    [buttonTemp setBackgroundImage:[UIImage imageNamed:@"backward_press"] forState:UIControlEventTouchDown];
                    break;
                default:
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
        //$$
        case buttonType_movieMusicTransparent://music跟movie同時都聽
            [buttonTemp addTarget:self action:@selector(movieButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            [buttonTemp addTarget:self action:@selector(musicButtonPressed) forControlEvents:UIControlEventTouchUpInside];
            
            [self.movieTransparentButton addObject:buttonTemp];
            buttonTemp.hidden=YES;
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
        [self blinkAnimationFor:blinkAnimationType_icon andState:blinkAnimationState_off];//其實關動畫的時候Focus沒有用
    }else if(stateInput==1){
        [self blinkAnimationFor:blinkAnimationType_icon andState:blinkAnimationState_off];
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
            [self blinkAnimationFor:blinkAnimationType_icon andState:blinkAnimationState_on];
        }
        else{
            [self blinkAnimationFor:blinkAnimationType_icon andState:blinkAnimationState_off];
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
            //^^
            if(self.gameState==gameState_pogDisable){}//
            else{
            //$$廣播給所有人
            [self showChance:2  andTarget:UNIMPORTANT];
            }
            break;
            
        case delayTimerEventType_video://
            //$$廣播給所有人
            [self showMoiveAndMusic:movieAndMusicState_movieSelect andSelectedView:UNIMPORTANT];
            break;
            
        case delayTimerEventType_video_selected:
            //$$廣播給其他人，只有andSelectedView是傳這台self.viewNumber
            //%%
            
            [self showMoiveAndMusic:movieAndMusicState_movieInitialization andSelectedView:self.viewNumber];

            break;
            
        case delayTimerEventType_music://
            //$$廣播給所有人
            [self showMoiveAndMusic:movieAndMusicState_musicSelect andSelectedView:UNIMPORTANT];
            break;
            
        case delayTimerEventType_music_selected:
            //$$廣播給其他人，只有andSelectedView是傳這台self.viewNumber
            //%%
            
            [self showMoiveAndMusic:movieAndMusicState_musicInitialization andSelectedView:self.viewNumber];
            
            break;
            
        case delayTimerEventType_game:
            [self showPogAndSelectedView:UNIMPORTANT];
            break;
        case delayTimerEventType_gameVeryGood:
            for(i=0;i<=4;i++){
                [[self.imageView_veryGood objectAtIndex:i] setHidden:YES];
            }
            break;
        default:
            break;
    }
    if(self.delayTimerEvent==delayTimerEventType_photo){
        
    }
    //[timer invalidate]; //停止 Timer
}

- (void)customAnimation:(NSTimer *)timer{

    switch (self.veryGoodAnimationFrameNumber) {
        case 2:
            [[self.imageView_veryGood objectAtIndex:4] setHidden:NO];
            break;
        case 4:
            [[self.imageView_veryGood objectAtIndex:2] setHidden:NO];
            break;
        case 5:
            [[self.imageView_veryGood objectAtIndex:3] setHidden:NO];
            break;
        case 10:
            [timer invalidate]; //停止 Timer            
        default:
            break;
    }


    self.veryGoodAnimationFrameNumber+=1;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    int i,j,k;
    
    //初始化gameState
    self.gameState=gameState_throwDice;
    self.whoseTurn=playerColor_orange;
    self.toolbarLightOn=YES;//其實剛開始會把燈還有音樂都打開，只是會在下面做
    self.toolbarMusicOn=YES;
    self.playerNumber=4;//##我沒有很認真把每個東西都修成能夠適應其他人數的狀態，所以現在self.playerNumber就跟4意思一模一樣
    self.overallRound=-1;
    self.toolbarPlayerState=playerStateType_none;
    self.stepToGo=0;
    
    //^^
    self.mapLongPressActivated=NO;
    
    
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
    
    for(i=0;i<=3;i++){//這邊還沒有做管理者(因為台科沒給圖)^^
        //其實總共要有5(人)x8(地點)x4(張照片)=160張，先假設每個使用者每個地點的照片都一樣，所以先放20張，然後地點都是0(中間那碼數字)
        //      P_ 0 _  0    _  0 .png
        //每台只要load會顯示在自己機台的照片，即最後一碼。
        //引導者使用的預設照片放在5裡面，暫時用不到
        NSMutableArray *secondLayer=[[NSMutableArray alloc] initWithCapacity:8];//八個地點
        
        for(j=0;j<=7;j++){
            //^^
            [secondLayer addObject:[UIImage imageNamed:[NSString stringWithFormat:@"P%d_%d_%d",i,j,self.viewNumber]]];
        }
        
        [self.imageLoadedList addObject:secondLayer];//這樣兩層是存：1.人 2.地點
        //長的：663,502
        //橫的：830,679
        
    }
    
    //人跟所在位置的對應
    HPPrimitiveType *ptTemp;
    self.placePositionMapping=[[NSMutableArray alloc] initWithCapacity:12];
    for (i=0; i<=11; i++) {
        ptTemp=[HPPrimitiveType alloc];
        switch (i) {
            case 0:
                ptTemp.Integer=0;
                break;
            case 1:
                ptTemp.Integer=0;
                break;
            case 2:
                ptTemp.Integer=1;
                break;
            case 3:
                ptTemp.Integer=2;
                break;
            case 4:
                ptTemp.Integer=2;
                break;
            case 5:
                ptTemp.Integer=3;
                break;
            case 6:
                ptTemp.Integer=4;
                break;
            case 7:
                ptTemp.Integer=4;
                break;
            case 8:
                ptTemp.Integer=5;
                break;
            case 9:
                ptTemp.Integer=6;
                break;
            case 10:
                ptTemp.Integer=6;
                break;
            case 11:
                ptTemp.Integer=7;
                break;
            default:
                break;
        }
        [self.placePositionMapping addObject:ptTemp];
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
    musicPlayer.delegate=self;
    
    
    //廉幕跟下面那條
    self.imageView_movie_background=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"musicMovie_movieMain"]];
    self.imageView_movie_background.hidden=YES;
    [self.imageView_movie_background setFrame:CGRectMake(0, 0, 768, 1024)];
    [self.view addSubview:self.imageView_movie_background];
    
    //$$
    //隱形的按鈕，左上右下分別有一個。我懶得在做判斷哪個是哪個了，反正應該不會有人按錯
    self.movieTransparentButton=[[NSMutableArray alloc] initWithCapacity:2];

    
    [self addButtonWithImage:@"transparent" andRect:CGRectMake(23, 78, 257, 257) andTag:UNIMPORTANT andType:buttonType_movieMusicTransparent];
    [self addButtonWithImage:@"transparent" andRect:CGRectMake(487, 687, 257, 257) andTag:UNIMPORTANT andType:buttonType_movieMusicTransparent];
    
    
    
    
    //歌名
    self.movieLabel = [[UILabel alloc] init];
    [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(90.0))];
    [self.movieLabel setFrame:CGRectMake( 74, 328, 156, 593 )];
    [self.movieLabel setFont:[UIFont fontWithName:@"STHeitiTC-Medium" size:90.0f]];
//    [self.movieLabel setFont:[UIFont fontWithName:@"DFYuan-W5-WIN-BF" size:90.0f]];
//    [self.movieLabel setFont:[UIFont fontWithName:@"Heiti TC" size:90.0f]];
    
    [self.movieLabel setTextColor: [UIColor blackColor]];
    [self.movieLabel setShadowColor:[UIColor lightGrayColor]];
    [self.movieLabel setTextAlignment:NSTextAlignmentCenter];
    [self.movieLabel setShadowOffset:CGSizeMake(3, 3)];
    [self.movieLabel setBackgroundColor:[UIColor clearColor]];
    [self.movieLabel setHidden:YES];
    [self.view addSubview: self.movieLabel];
    
    
    
    
    
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
        //先加進六張會飛進來的牌
        self.imageView_pogFlyIn=[[NSMutableArray alloc] initWithCapacity:6];
        self.pogSheetFlyIn=[[NSMutableArray alloc] initWithCapacity:6];//
        HPPrimitiveType *primitiveTemp;
        
        self.imageView_pogQuestion=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pog_question_0"]];//##之後要改成隨機。但總之應該只有viewNumber為3那台有機會使用到這個ImageView
        [self.imageView_pogQuestion setHidden:YES];
        [self.view addSubview:self.imageView_pogQuestion];
        
        UIImageView *imageViewTemp;
        for(i=0;i<=5;i++){
            imageViewTemp=[[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"pog_sheet_1"]]];
            switch (i) {
                case 0:
                    imageViewTemp.frame=CGRectMake(20, 13, 344, 340);
                    break;
                case 1:
                    imageViewTemp.frame=CGRectMake(212, 13, 344, 340);
                    break;
                case 2:
                    imageViewTemp.frame=CGRectMake(429, 13, 344, 340);
                    break;
                case 3:
                    imageViewTemp.frame=CGRectMake(8, 298, 344, 340);
                    break;
                case 4:
                    imageViewTemp.frame=CGRectMake(200, 298, 344, 340);
                    break;
                case 5:
                    imageViewTemp.frame=CGRectMake(417, 298, 344, 340);
                    break;
                default:
                    break;
            }
            imageViewTemp.hidden=YES;
            [self.view addSubview:imageViewTemp];
            [self.imageView_pogFlyIn addObject:imageViewTemp];

            primitiveTemp=[[HPPrimitiveType alloc] init];
            primitiveTemp.Integer=999;
            [self.pogSheetFlyIn addObject:primitiveTemp];
        }

    }else{
        //ㄤ仔鑣基礎
        self.button_pogPaper=[[NSMutableArray alloc] initWithCapacity:3];//0,1:兩個鑣 2:原紙
        
        //加鑣進去
        [self addButtonWithImage:[NSString stringWithFormat:@"pog_sheet_%d",self.viewNumber*2] andRect:CGRectMake(202, 139, 391, 387) andTag:tag_button_pogUp andType:buttonType_pogPaper];
        [self addButtonWithImage:[NSString stringWithFormat:@"pog_sheet_%d",(self.viewNumber*2+1)] andRect:CGRectMake(202, 574, 391, 387) andTag:tag_button_pogDown andType:buttonType_pogPaper];
        
        
        //ㄤ仔標的兩個閃光
        self.imageView_blink_pog=[[NSMutableArray alloc] initWithCapacity:2];
        
        [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                        [UIImage imageNamed:@"pogBlink"],[UIImage imageNamed:@"transparent"],nil]
                               andRect:CGRectMake(202, 139, 391, 387)
                               andType:blinkAnimationType_pog];
        
        [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                        [UIImage imageNamed:@"pogBlink"],[UIImage imageNamed:@"transparent"],nil]
                               andRect:CGRectMake(202, 574, 391, 387)
                               andType:blinkAnimationType_pog];

        
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
    
    
    
    //$$改了位置
    //問題卡的閃光  //頗萬用
    //閃光array的順序是：0:白，1~4:紅黃綠橘
    self.image_questionCard_blink=[[NSMutableArray alloc] initWithCapacity:5];//array一定要初始化，不然很容易產生de不出來的bug
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_W"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_circleWithoutColor];
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_R"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_circleWithoutColor];
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_Y"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_circleWithoutColor];
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_G"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_circleWithoutColor];
    [self blinkArrayAdderWithArray:[NSArray arrayWithObjects:
                                    [UIImage imageNamed:@"questionCard_light_O"],[UIImage imageNamed:@"transparent"],nil]
                           andRect:rectTemp
                           andType:blinkAnimationType_circleWithoutColor];
    
    

    
    //^^改了位置
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

    imageViewTemp.frame=CGRectMake(-500,-750,1754,2481);
    
    CABasicAnimation *fullRotationAnimation;
    fullRotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    fullRotationAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    fullRotationAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI];
    fullRotationAnimation.duration = 3;
    fullRotationAnimation.repeatCount = 5000;
    [imageViewTemp.layer addAnimation:fullRotationAnimation forKey:@"360"];
    
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
    
    //^^換位置
    //左右簾幕
    self.imageView_movie_curtainLeft=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"musicMovie_curtainLeft"]];
    self.imageView_movie_curtainLeft.frame=CGRectMake(0, -22, 768, 550);
    self.imageView_movie_curtainLeft.hidden=YES;
    [self.view addSubview:self.imageView_movie_curtainLeft];
    
    
    
    self.imageView_movie_curtainRight=[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"musicMovie_curtainRight"]];
    self.imageView_movie_curtainRight.frame=CGRectMake(0, 498, 768, 550);
    self.imageView_movie_curtainRight.hidden=YES;
    [self.view addSubview:self.imageView_movie_curtainRight];
    
    
    
    
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
    [self addButtonWithImage:@"back_to_map" andRect:CGRectMake(400,600, 97, 44) andTag:tag_button_toolbar_0_map andType:buttonType_toolbar_function];
    UIButton *button_toolbar_number_temp = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.button_toolbar_number addObject:button_toolbar_number_temp];
    [self addButtonWithImage:@"button_1_dark" andRect:CGRectMake(400,700, 97, 44) andTag:tag_button_toolbar_number_1 andType:buttonType_toolbar_number];
    [self.button_toolbar_number addObject:button_toolbar_number_temp];
    [self.button_toolbar_number addObject:button_toolbar_number_temp];
    [self.button_toolbar_number addObject:button_toolbar_number_temp];
    [self.button_toolbar_number addObject:button_toolbar_number_temp];
    [self.button_toolbar_number addObject:button_toolbar_number_temp];
    //TESTEND

    
    
    //TEST
    [self addButtonWithImage:@"button_1_dark" andRect:CGRectMake(609,900, 97, 44) andTag:tag_button_test1 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_2_dark" andRect:CGRectMake(498,900, 97, 44) andTag:tag_button_test2 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_3_dark" andRect:CGRectMake(390,900, 97, 44) andTag:tag_button_test3 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_4_dark" andRect:CGRectMake(280,900, 97, 44) andTag:tag_button_test4 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_5_dark" andRect:CGRectMake(170,900, 97, 44) andTag:tag_button_test5 andType:buttonType_TEST];
    [self addButtonWithImage:@"button_6_dark" andRect:CGRectMake(60,900, 97, 44) andTag:tag_button_test6 andType:buttonType_TEST];
    //TESTEND
    
    
    //TEST
    
    
    
    

//    pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
//    pathAnimation.duration = 0.5f;
//    pathAnimation.calculationMode = kCAAnimationCubic;
//    pathAnimation.fillMode = kCAFillModeForwards;
//    pathAnimation.removedOnCompletion = NO;

    
    
    
    
    // 位移A
    
//    //在做位移時，他的定址會以圖片中心為準，所以要加到中心的一半
//    CGMutablePathRef pointPath = CGPathCreateMutable();
//    
//    CGPathMoveToPoint(pointPath, NULL,TESTimageViewTemp.frame.origin.x+TESTimageViewTemp.frame.size.width/2,TESTimageViewTemp.frame.origin.y+TESTimageViewTemp.frame.size.height/2);//原先的point
//    
//    CGPathAddLineToPoint(pointPath, NULL,429+TESTimageViewTemp.frame.size.width/2,13+TESTimageViewTemp.frame.size.height/2);//要到的point
//    pathAnimation.path = pointPath;
//    CGPathRelease(pointPath);
//    [TESTimageViewTemp.layer addAnimation:pathAnimation forKey:@"pathAnimation"];


    
    
    
    
    
//    TESTimageViewTemp.frame=CGRectMake(newImageViewX, newImageViewY, tempImageView.frame.size.width, tempImageView.frame.size.height);
    
    
    //TESTEND

    
    
    //load最後，才進行棋子擺放
    [self playerHandoff];
    
    
    
    
}

-(void)showPogAndSelectedView:(int)selectedPog{
    int i;
    if(selectedPog==EXIT){
        self.pogPoked=NO;//初始化，自己沒被戳過
        [self.imageView_movie_background_color setHidden:YES];
        if(self.viewNumber==3){//問題卡
            [self.imageView_pogQuestion setHidden:YES];
            for(i=0;i<=5;i++){
                [[self.imageView_pogFlyIn objectAtIndex:i] setHidden:YES];
            }
            
        }else{//腌仔鑣
            for(i=0;i<=2;i++){
                [[self.button_pogPaper objectAtIndex:i] setHidden:YES];
            }
            [self blinkAnimationFor:blinkAnimationType_pog andState:blinkAnimationState_off];
        }
    }else{
        switch (self.gameState) {
            case gameState_pogInitialization://初始化問題卡跟戳戳樂
                self.pogPoked=NO;//初始化，自己沒被戳過
                [self backgroundColorReset:2];//讀木頭桌子
                [self.imageView_movie_background_color setHidden:NO];
                if(self.viewNumber==3){//問題卡
                    [self.imageView_pogQuestion setHidden:NO];
                    self.gameState=gameState_pogDisable;
                    
                    self.pogSheetFlyInNumber=0;
                    for(i=0;i<=5;i++){
                        [[self.imageView_pogFlyIn objectAtIndex:i] setHidden:YES];
                    }
                    
                }else{//腌仔鑣
                    for(i=0;i<=2;i++){
                        [[self.button_pogPaper objectAtIndex:i] setHidden:NO];
                    }
                    self.gameState=gameState_pogAvaliable;
                }
                break;
                
            case gameState_pogDisable://讓戳戳樂不能戳or戳的時候沒有用
                if(self.viewNumber==3){//問題卡
                }else{//腌仔鑣
                    if(!self.pogPoked){
                        [self.questionCard_black setHidden:NO];//還沒被戳過的話才暗掉
                    }
                }
                break;
                
            case gameState_pogEnable://讓戳戳樂可以戳
                if(self.viewNumber==3){//問題卡不用更新
                }else{//腌仔鑣
                    if(!self.pogPoked){
                        [self.questionCard_black setHidden:YES];//還沒被戳過才需要再亮起來
                        
                    }
                }
                break;
                
            case gameState_pogAvaliable://戳戳樂可以戳的時候，戳了。只有ㄤ仔標有這個state
                if(!self.pogPoked){//沒戳過，播放戳的動畫
                    [[self.button_pogPaper objectAtIndex:2] setHidden:YES];
                    [self.imageView_pogPaperTorn startAnimating];
                    self.pogPoked=true;
                    //                $$在這邊呼叫其他台的
                    //                self.gameState=gameState_pogDisable;
                    //                [self showPogAndSelectedView:UNIMPORTANT];
                    //                    讓其他台暗掉不能被戳
                    [self blinkAnimationFor:blinkAnimationType_pog andState:blinkAnimationState_on];
                    
                }else{//戳過了，接下來就可以選上面或下面
                    HPPrimitiveType *primitiveTemp=[self.pogSheetMapping objectAtIndex:(selectedPog+self.viewNumber*2)];
                    if(primitiveTemp.Integer==0){
                        //##飛起來再掉下去
                        NSLog(@"飛起來再掉下去");  
                    }else if (primitiveTemp.Integer==1){
                        //##飛過去
                        NSLog(@"飛fly~");
                        //                $$在這邊呼叫viewNumber=3的
                        //                self.gameState=gameState_pogFlyIn;
                        //                [self showPogAndSelectedView:(selectedPog+self.viewNumber*2)];
                        //                    讓問題卡那台，有人飛進去
                        //                    這個一定要在這裡call~
                        
                        [[self.button_pogPaper objectAtIndex:selectedPog] setHidden:YES];
                        primitiveTemp.Integer=2;
                        [self blinkAnimationFor:blinkAnimationType_pog andState:blinkAnimationState_on];//再重新讀取
                        //                $$在這邊呼叫其他台的
                        //                self.gameState=gameState_pogEnable;
                        //                [self showPogAndSelectedView:UNIMPORTANT];
                        //                    讓其他台可以再被戳
                        
                        
                        
                    }else if(primitiveTemp.Integer==2){//被按過了就消失了，那就按不到
                    }
                }
                break;
                
            case gameState_pogFlyIn://問題卡被飛進ㄤ仔鑣(只有問題卡有這個state，而且是被別人呼叫的，之後自己回到disable)
                if(self.viewNumber==3){
                    //這邊傳進來的selectedPog是完整的值(0~5)
                    UIImageView *imageViewTemp;
                    HPPrimitiveType *primitiveTemp=[self.pogSheetMapping objectAtIndex:selectedPog];
                    if(primitiveTemp.Integer==1){//如果是正確的而且還沒有飛過來過
                        //##飛進來ㄅ動畫
    //                    pogSheetFlyInNumber表示現在是總共幾張圖飛進來了
                        NSLog(@"FIN%d",self.pogSheetFlyInNumber);
                        imageViewTemp=[self.imageView_pogFlyIn objectAtIndex:self.pogSheetFlyInNumber];
                        [imageViewTemp setImage:[UIImage imageNamed:[NSString stringWithFormat:@"pog_sheet_%d",selectedPog]]];
                        [imageViewTemp setHidden:NO];
                        
                        primitiveTemp.Integer=2;
                        self.pogSheetFlyInNumber+=1;
                        
                        //^^
                        UIImageView *imTemp= [self.imageView_veryGood objectAtIndex:0];
                        [imTemp setImage:[self.image_veryGood_background objectAtIndex:self.whoseTurn]];
                        [[self.imageView_veryGood objectAtIndex:0] setHidden:NO];
                        [[self.imageView_veryGood objectAtIndex:1] setHidden:NO];
                        
                        
                        //TEST
                        
                        //顯示你好棒
                        self.veryGoodAnimationFrameNumber=0;
                        [NSTimer scheduledTimerWithTimeInterval:1 //要用timer的話就用這行
                                                         target:self
                                                       selector:@selector(customAnimation:)
                                                       userInfo:nil
                                                        repeats:YES];
                        
                        self.delayTimerEvent=delayTimerEventType_chanceVeryGood;
                        [NSTimer scheduledTimerWithTimeInterval:10 //要用timer的話就用這行
                                                         target:self
                                                       selector:@selector(timerEvent:)
                                                       userInfo:nil
                                                        repeats:NO];

                        
                    }
                    self.gameState=gameState_pogDisable;
                }
                break;
                
            default:
                break;
        }
    }

}

- (IBAction)pogButtonPressed:(id)sender{
    //tag:
    //tag_button_pogDown
    UIButton *inputButton=(UIButton *)sender;
    NSLog(@"%d",inputButton.tag);
    if(self.gameState==gameState_pogAvaliable){
        [self showPogAndSelectedView:inputButton.tag-tag_button_pogUp];
    }
}


-(void)showMoiveAndMusic:(movieAndMusicState)stateInput andSelectedView:(int)selectedViewNumber{
    
    NSString *movieResourcePath;//switch-case裡面沒辦法初始化變數，因為程式會不確定這個東西到底有沒有辦法被declared
    NSURL *movieResourceUrl;
    
    NSString *soundResourcePath;
    NSURL *soundResourceUrl;
    
    CATransition *applicationLoadViewIn;
    
    
    

    
    
    
    
    
    
    switch (stateInput) {
        case movieAndMusicState_movieSelect://第一次初始化，給大家選
            self.movieOrMusicNow=movieOrMusic_movie;//告訴系統現在是進入影片模式->讓播放鍵可以知道要放影片還是音樂
            //##沒做廉幕拉開
            

            //^^
            //一定要用block包起來
            [self.imageView_movie_curtainLeft setHidden:NO];
            [self.imageView_movie_curtainRight setHidden:NO];
            {
                [UIView animateWithDuration:2.0
                                 animations:^{
                                        //要漸變的結果是怎樣
                                        self.imageView_movie_curtainLeft.transform = CGAffineTransformMakeTranslation(0, -572);
                                        self.imageView_movie_curtainRight.transform = CGAffineTransformMakeTranslation(0, 600);
                                 }completion:^(BOOL finished){
                                 }
                 ];
            }
            
            //用來blocking顯示的，因為他裡面有宣告自己的變數，所以一定要用block包在外面。
//            [UIView animateWithDuration:2.0
//                             animations:^{
                                    //第一階段要播的
//                             }
//                             completion:^(BOOL finished){
//                                 [UIView animateWithDuration:2.0
//                                                  animations:^{
                                                        //第二階段要播的
//                                                  }
//                                                  completion:^(BOOL finished){
//                                                      [UIView animateWithDuration:2.0
//                                                                       animations:^{
                                                                            //第三階段要播的
//                                                                       }
//                                                                       completion:^(BOOL finished){
//                                                                           
//                                                                           ;
//                                                                       }];
//                                                      ;
//                                                  }];
//                                 
//                             }];
            //TESTEND
            
            
            //顯示隱形按鈕
            [[self.movieTransparentButton objectAtIndex:0]setHidden:NO];
            [[self.movieTransparentButton objectAtIndex:1]setHidden:NO];
            
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
                
                [self blinkAnimationFor:blinkAnimationType_circleWithoutColor andState:blinkAnimationState_movieMusicLeftUp];
                
                
            }else if(self.whoseTurn==playerColor_green||self.whoseTurn==playerColor_orange){
                
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0))];
                
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieLabel setFrame:CGRectMake( 540, 115, 156, 593 )];
                
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(0, 149, 542, 725)];
                
                [self blinkAnimationFor:blinkAnimationType_circleWithoutColor andState:blinkAnimationState_movieMusicRightDown];
            }
            
            
            [self.imageView_movie_background setFrame:CGRectMake(0, 0, 768, 1024)];
            
            
            
            //按鈕式圖片
            
            [self.movieThumbnailButton setBackgroundImage:[moviePlayer thumbnailImageAtTime:10.0
                                                                                 timeOption:MPMovieTimeOptionNearestKeyFrame] forState:UIControlStateNormal];
            [self.movieThumbnailButton setHidden:NO];
            
            
            break;
            
        case movieAndMusicState_movieInitialization:
            
            //^^
            //Animation執行結束之後才能開始做事情
            
            {
                
                [UIView animateWithDuration:2.0
                     animations:^{
                         //要漸變的結果是怎樣
                         self.imageView_movie_curtainLeft.transform = CGAffineTransformMakeTranslation(0, 0);
                         self.imageView_movie_curtainRight.transform = CGAffineTransformMakeTranslation(0, 0);
                     }completion:^(BOOL finished){
                         
                        //^^
                        self.toolbarPlayerState=playerStateType_none;
                         NSString *movieResourcePath;//block裡面要在宣告一次囧...
                         NSURL *movieResourceUrl;
                         
                         movieResourcePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"movie_%d",selectedViewNumber] ofType:@"mp4"];//##讀取的影片內容之後應該會再篩選過
                         self.movieMusicSelected=selectedViewNumber;//把「選到哪台」存起來
                         movieResourceUrl = [NSURL fileURLWithPath:movieResourcePath];
                         [moviePlayer setContentURL:movieResourceUrl];
                         [moviePlayer setShouldAutoplay:NO];
                         //%%
                         [self blinkAnimationFor:blinkAnimationType_circleWithColor andState:blinkAnimationState_off];
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
                         
                         
                         //把隱形按鈕拔掉
                         [[self.movieTransparentButton objectAtIndex:0]setHidden:YES];
                         [[self.movieTransparentButton objectAtIndex:1]setHidden:YES];
                         

                          [UIView animateWithDuration:2.0
                                   animations:^{
                                       self.imageView_movie_curtainLeft.transform = CGAffineTransformMakeTranslation(0, -572);
                                       self.imageView_movie_curtainRight.transform = CGAffineTransformMakeTranslation(0, 600);
                                   }
                                   completion:^(BOOL finished){

                                       ;
                                   }];
                        }
                 ];
            }

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
            [[self.movieTransparentButton objectAtIndex:0]setHidden:YES];
            [[self.movieTransparentButton objectAtIndex:1]setHidden:YES];
            //^^補上
            [self.imageView_movie_curtainLeft setHidden:YES];
            [self.imageView_movie_curtainRight setHidden:YES];
            break;
            
            
            
        case movieAndMusicState_musicSelect://音樂初始化，給大家選
            
            //^^
            [self.imageView_movie_curtainLeft setHidden:NO];
            [self.imageView_movie_curtainRight setHidden:NO];
            self.toolbarPlayerState=playerStateType_none;
            {
                [UIView animateWithDuration:2.0
                                 animations:^{
                                     //要漸變的結果是怎樣
                                     self.imageView_movie_curtainLeft.transform = CGAffineTransformMakeTranslation(0, -572);
                                     self.imageView_movie_curtainRight.transform = CGAffineTransformMakeTranslation(0, 600);
                                 }completion:^(BOOL finished){
                                 }
                 ];
            }
            
            
            self.movieOrMusicNow=movieOrMusic_music;
            self.gameState=gameState_musicDisplayInitialization;
            //##沒做廉幕拉開
            
            //顯示隱形按鈕
            [[self.movieTransparentButton objectAtIndex:0]setHidden:NO];
            [[self.movieTransparentButton objectAtIndex:1]setHidden:NO];
            
            
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
                
                [self blinkAnimationFor:blinkAnimationType_circleWithoutColor andState:blinkAnimationState_movieMusicLeftUp];
                
                
            }else if(self.whoseTurn==playerColor_green||self.whoseTurn==playerColor_orange){
                
                [self.imageView_movie_background setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(180.0))];
                
                [self.movieLabel setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieLabel setFrame:CGRectMake( 540, 115, 156, 593 )];
                
                
                [self.movieThumbnailButton setTransform:CGAffineTransformRotate(CGAffineTransformIdentity,RADIANS(270.0))];
                [self.movieThumbnailButton setFrame:  CGRectMake(0, 149, 542, 725)];
                
                [self blinkAnimationFor:blinkAnimationType_circleWithoutColor andState:blinkAnimationState_movieMusicRightDown];
            }
            
            
            [self.imageView_movie_background setFrame:CGRectMake(0, 0, 768, 1024)];
            
            
            
            //按鈕式圖片
            
            [self.movieThumbnailButton setBackgroundImage:[UIImage imageNamed:[NSString stringWithFormat:@"musicPhoto_%d",self.viewNumber]] forState:UIControlStateNormal];//##這邊應該是要填入音樂的圖
            
            
            
            [self.movieThumbnailButton setHidden:NO];
            
            
            
            break;
            
        case movieAndMusicState_musicInitialization:
            {
                [UIView animateWithDuration:2.0
                     animations:^{
                         //要漸變的結果是怎樣
                         self.imageView_movie_curtainLeft.transform = CGAffineTransformMakeTranslation(0, 0);
                         self.imageView_movie_curtainRight.transform = CGAffineTransformMakeTranslation(0, 0);
                     }completion:^(BOOL finished){
                
                        self.movieMusicSelected=selectedViewNumber;//把「選到哪台」存起來
                        //顯示廉幕跟文字
                        //%%
                        [self blinkAnimationFor:blinkAnimationType_circleWithColor andState:blinkAnimationState_off];
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
                        [[self.movieTransparentButton objectAtIndex:0]setHidden:YES];
                        [[self.movieTransparentButton objectAtIndex:1]setHidden:YES];
                         
                         
                         [UIView animateWithDuration:2.0
                                          animations:^{
                                              self.imageView_movie_curtainLeft.transform = CGAffineTransformMakeTranslation(0, -572);
                                              self.imageView_movie_curtainRight.transform = CGAffineTransformMakeTranslation(0, 600);
                                          }
                                          completion:^(BOOL finished){
                                              
                                              ;
                                          }];
                         
                 }];
            }
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
            //%%
            [[self.movieTransparentButton objectAtIndex:0]setHidden:YES];
            [[self.movieTransparentButton objectAtIndex:1]setHidden:YES];
            self.toolbarPlayerState=playerStateType_none;
            [musicPlayer stop];
            [self.imageView_movie_background_color setHidden:YES];
            [self.movieThumbnailButton setHidden:YES];
            
            
            break;
            
            
        default:
            break;
    }
    
}

-(void)movieButtonPressed{
    if(self.delayTimerEvent==delayTimerEventType_video){//可以按的時候才給他按
        //%%
        //把自己的那個圓形的燈開亮一下
        [self blinkAnimationFor:blinkAnimationType_circleWithColor andState:blinkAnimationState_on];
        
        self.delayTimerEvent=delayTimerEventType_video_selected;
        
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(timerEvent:)
                                       userInfo:nil
                                        repeats:NO];
    }
    
}
-(void)musicButtonPressed{
    //$$廣播給其他人，只有selectedView是self.viewNumber
    //%%
    if(self.delayTimerEvent==delayTimerEventType_music){//可以按的時候才給他按
        //%%
        //把自己的那個圓形的燈開亮一下
        [self blinkAnimationFor:blinkAnimationType_circleWithColor andState:blinkAnimationState_on];
        
        self.delayTimerEvent=delayTimerEventType_music_selected;
        
        [NSTimer scheduledTimerWithTimeInterval:1
                                         target:self
                                       selector:@selector(timerEvent:)
                                       userInfo:nil
                                        repeats:NO];
    }
    
    
}
-(void)stopAudio{
    self.toolbarPlayerState=playerStateType_prepared;
    if(self.viewNumber==0){
        UIButton *buttonTemp=[self.button_toolbar_function objectAtIndex:(tag_button_toolbar_2_play-tag_button_toolbar_Base-1)];
        [buttonTemp setBackgroundImage:[UIImage imageNamed:@"play_and_pause"] forState:UIControlStateNormal];
    }
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{//音樂停止時
    NSLog(@"fuckyou");
}

//TEST 專門用來測試功能的button們
- (IBAction)buttonHit_TEST:(id)sender{
    UIButton *buttonTemp=(UIButton *)sender;
    UIButton *inputButton=(UIButton *)sender;
    NSLog(@"%d",inputButton.tag);
    switch (inputButton.tag) {
        case tag_button_test1:
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
                case gameState_pogDisable:
                case gameState_pogAvaliable:
                    
                    [self showPogAndSelectedView:EXIT];
                    [self playerHandoff];//換人了
                    break;
                default:
                    break;
            }
            break;
        case tag_button_test2:
            self.gameState=gameState_pogFlyIn;
            [self showPogAndSelectedView:1];
            break;
            break;
        case tag_button_test3:
            self.gameState=gameState_pogFlyIn;
            [self showPogAndSelectedView:2];
            break;
        case tag_button_test4:
            self.gameState=gameState_pogFlyIn;
            [self showPogAndSelectedView:3];
            break;
        case tag_button_test5:
            self.gameState=gameState_pogFlyIn;
            [self showPogAndSelectedView:UNIMPORTANT];
            break;
        case tag_button_test6:
            
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
            
            break;
        default:
            break;
    }
}
//TESTEND

@end
