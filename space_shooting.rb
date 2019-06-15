require 'gosu'
require 'Time'

def degree(current_x, current_y, target_x, target_y)
    radian = Math.atan2(target_y - current_y, target_x - current_x)
    deg = radian * 180 / Math::PI
    return deg
end

class Invader < Gosu::Window
    def initialize
        super 450, 600
        self.caption = "Invader Game"

        # @bg_image = Back_image.new #default y = -600
        @bg_images = Array.new.push(Back_image.new).push(Back_image.new).push(Back_image.new)
        @bg_images[0].set_y(0) #一枚目の背景のy軸を0にセット

        @start_se = Gosu::Sample.new("media/se_start.mp3")

        @logo_image = Gosu::Image.new("media/logo.png")
        @back_music = Gosu::Song.new("media/bgm.mp3")
        @shoot_se = Gosu::Sample.new("media/shoot.wav")
        @destroy_se = Gosu::Sample.new("media/destroy.wav")
        @play_destroy_se = false

        @player = Player.new
        @bullets = Array.new #弾丸を全て
        @bullets_timestamp = Array.new #発射された弾丸のタイムスタンプ
        @hit_bullet = Array.new
        @key_push = false #スペースキーが押されているかどうか
        @player_hp = 3
        @image_hp = Gosu::Image.new("media/heart.png")

        @score = 0

        @enemy1 = Enemy.new(100)
        @num1 = 1.5
        @enemy2 = Enemy.new(150)
        @num2 = 0.0
        @enemies = [@enemy1, @enemy2]
        @enemy_bullets = Array.new
        @enemy_bullets_timestamp = Array.new
        @bullet_flag1 = false
        @bullet_flag2 = false
        @se_player_hit = Gosu::Sample.new("media/se_player_hit.mp3")
        @se_enemy_shoot = Gosu::Sample.new("media/se_enemy_shoot.mp3")
        @se_enemy_bullet_destroy = Gosu::Sample.new("media/se_enemy_bullet_destroy.mp3")

        @explosions = Array.new
        @explosions_time = Array.new

        @font1 = Gosu::Font.new(20)
        @font2 = Gosu::Font.new(30)
        @font3 = Gosu::Font.new(16)
        @font4 = Gosu::Font.new(40)
        @font5 = Gosu::Font.new(50)

        @scene = :start
    end

    def update
        case @scene
        when  :start
            # @scene == 2 if button_down? Gosu::KbSpace
        when  :game
            # プレイヤーの動き
            if button_down? Gosu::KbLeft
                @player.move_left
            end
            if button_down? Gosu::KbRight
                @player.move_right
            end
            if button_down? Gosu::KbUp
                @player.move_up
            end
            if button_down? Gosu::KbDown
                @player.move_down
            end
            @player.move

            # 弾をSPACEキーを一回おすと、一発だけ発射する
            if not(@key_push) && (button_down? Gosu::KbSpace)
                @bullets.push(Bullet.new(@player.x,@player.y))
                @bullets_timestamp.push(Time.now) # 撃った弾が難病に発射されたか記録
                @shoot_se.play
                @key_push = true
            end
            if @key_push
                if !(button_down? Gosu::KbSpace)
                    @key_push = false
                end
            end
            
            #画面外に消えた弾と発射から１秒たった弾のカウントを消す
            @bullets.delete_if {|bullet| bullet.y <= 0}
            @bullets_timestamp.delete_if {|time| time <= Time.now - 1}

            @enemies.each do |enemy|
                @bullets.delete_if do |bullet,i|
                    if bullet.hit(enemy.x, enemy.y)
                        @score += 10
                        @destroy_se.play
                    end
                end
            end
            
            
            #敵の動き
            @num1 += 0.01
            @enemy1.move_x(@num1,150)
            @num2 += 0.02
            @enemy2.move_x(@num2,250)

            #敵の弾
            #@enemy1の弾発射
            if not(@bullet_flag1) && Time.now.sec % 2 == 0
                @enemy_bullets.push(Enemy_bullet.new(@enemy1.x, @enemy1.y, @player.x, @player.y))
                @enemy_bullets_timestamp.push(Time.now)
                @se_enemy_shoot.play
                @bullet_flag1 = true
            end
            if @bullet_flag1 && Time.now.sec % 2 != 0
                @bullet_flag1 = false
            end
            #@enemy2の弾発射
            if not(@bullet_flag2) && Time.now.sec % 3 == 0
                @enemy_bullets.push(Enemy_bullet.new(@enemy2.x, @enemy2.y, @player.x, @player.y))
                @enemy_bullets_timestamp.push(Time.now)
                @se_enemy_shoot.play
                @bullet_flag2 = true
            end
            if @bullet_flag2 && Time.now.sec % 3 != 0
                @bullet_flag2 = false
            end
            # 弾の当たり判定
            @enemy_bullets.delete_if do |bullet| 
                if @player.player_hit?(bullet.x, bullet.y)
                    @se_player_hit.play
                    @player_hp -= 1
                    @explosions.push(Explosion.new(bullet.x,bullet.y)) 
                    @explosions_time.push(Time.now)
                end
            end

            @enemy_bullets_timestamp.delete_if do |t|
                if t <= Time.now - 10
                    @explosions.push(Explosion.new(@enemy_bullets[0].x,@enemy_bullets[0].y)) 
                    @explosions_time.push(Time.now)
                    @enemy_bullets.delete_at(0)
                    @se_enemy_bullet_destroy.play
                end
            end

            @explosions_time.delete_if do |t|
                if t < Time.now - 1
                    @explosions.delete_at(0)
                end
            end

            #画面遷移
             @scene = :end if @player_hp <= 0

        when :end
           if button_down? Gosu::KB_SPACE
            @gametime = Time.now
            @start_se.play
            @player_hp = 3
            @score = 0
            @bullets = []
            @bullets_timestamp = []
            @enemy_bullets = []
            @enemy_bullets_timestamp = []
            @player = Player.new
            @scene = :game
           end
        end

        #流れる背景を作りたい
        if @bg_images.length <= 2
            @bg_images.push(Back_image.new)
        end

        @bg_images.delete_at(0) if @bg_images[0].y >= 600

        if button_down? Gosu::KB_ESCAPE
            close
        end
    end

    def draw
        case @scene
        when :start
            if button_down? Gosu::KB_SPACE
                @gametime = Time.now
                @start_se.play
                @scene = :game
            end
            @logo_image.draw(35,100,1)
            if Time.now.sec % 2 == 0
                @font2.draw("press space to start", 110, 430, 1, 1.0, 1.0, Gosu::Color::WHITE)
            end
        when :game
            
            @player.draw
            @bullets.each do |bullet| 
                bullet.draw
            end

            #敵の描画
            @enemy1.draw
            @enemy2.draw
            #敵の弾の描画
            @enemy_bullets.each do |bullet| 
                bullet.draw(@player.x, @player.y)
            end

            @explosions.each { |ex| ex.draw }
            
            
            @font1.draw("fps:#{Gosu.fps}", 10, 5, 1, 1.0, 1.0, Gosu::Color::YELLOW)
            # @font1.draw("表示弾数 : #{@bullets.length}", 10, 70, 1, 1.0, 1.0, Gosu::Color::WHITE)
            # @font1.draw("連打/秒  : #{@bullets_timestamp.length}", 10, 50, 1, 1.0, 1.0, Gosu::Color::WHITE)
            # @font1.draw("連打/秒  : #{@bullets_timestamp.length}", 10, 50, 1, 1.0, 1.0, Gosu::Color::WHITE)
            # @font1.draw("#{@enemy_bullets[0].re_angle}", 10, 50, 1, 1.0, 1.0, Gosu::Color::WHITE) if @enemy_bullets.length >= 1
            @font1.draw("Score   : #{@score}", 10, 30, 1, 1.0, 1.0, Gosu::Color::WHITE)
            # @font1.draw("SpaceKeyDown?: #{@key_push.to_s}", 10, 75, 1, 1.0, 1.0, Gosu::Color::YELLOW)
            @displaytime = Time.now-@gametime
            @font1.draw("Time:#{format('%03d', @displaytime.to_i)}", 355, 5, 1, 1.0, 1.0, Gosu::Color::YELLOW)
            # @font1.draw("敵の弾: #{format('%02d', @enemy_bullets.length)}", 360, 25, 1, 1.0, 1.0, Gosu::Color::WHITE)
            @font3.draw("HP :", 450/2 - 55, 550, 1, 1.0, 1.0, Gosu::Color::WHITE)
            @player_hp.times do |t|
                x = 450/2 + 5
                @image_hp.draw(x+(t-1)*(8+16),550,1,1,1)
            end
        when :end
            @font5.draw_text("GAME OVER", 90, 200, 1, 1.0, 1.0, Gosu::Color::WHITE) if Time.now.sec % 2 == 0
            @font4.draw_text("Your score is ...", 100, 350, 1, 1.0, 1.0, Gosu::Color::WHITE)
            @font4.draw_text("#{@score}", 210, 400, 1, 1.0, 1.0, Gosu::Color::WHITE)
            @font2.draw_text("SPACE for SPACE again !", 85, 470, 1, 1.0, 1.0, Gosu::Color::WHITE)
        end

        @bg_images.each {|image| image.draw}
        @back_music.play
    end
end

class Player
    def initialize
        @image = Gosu::Image.new("media/starfighter.bmp")
        @x =  450/2
        @vel_x = @vel_y = 0.0
        @y = 500
        @score = 0
    end

    def move_left
        @vel_x -= 0.5
    end

    def move_right
        @vel_x += 0.5
    end

    def move_up
        @vel_y -= 0.5
    end

    def move_down
        @vel_y += 0.5
    end

    def move
        @x += @vel_x
        @y += @vel_y
        @vel_x *= 0.9
        @vel_y *= 0.9

        @x %= 450
        @y <= 10  ? @y = 10  : @y = @y
        @y >= 590 ? @y = 590 : @y = @y 
    end

    def draw
        @image.draw_rot(@x, @y, 1, 0)
    end

    def player_hit?(enemy_bullet_x,enemy_bullet_y)
        if (@x-18 <= enemy_bullet_x && @x+18 >= enemy_bullet_x) && (@y-20 <= enemy_bullet_y && @y+22 >= enemy_bullet_y)
            return true
        else
            return false
        end
    end

    def x
        @x
    end

    def y
        @y
    end
end

class Bullet
    # attr_accessor :x

    def initialize(x,y)
        @image = Gosu::Image.new("media/missile.png")
        @x = x
        @y = y
        @is_hit = false
    end

    def draw
        @y -= 6.5
        @image.draw(@x-8, @y-20, 1, 1, 1)
    end

    def x
        @x
    end
    def y
        @y
    end

    def hit(enemy_x,enemy_y)
        if (@x >= enemy_x - 5 && @x <= enemy_x +20) && (@y >= enemy_y -5 && @y <= enemy_y +35)
            @is_hit = true
            return true
        end
    end

    def is_hit
        @is_hit
    end
end

class Enemy
    def initialize(y)
        @enemy = Gosu::Image.new("media/enemy.png")
        @x, @y = 0, y
    end

    def move_x(num,x)
        @x = x + Math.cos(num) * 100
    end

    def draw
        @enemy.draw(@x, @y, 4)
    end

    def x
        @x
    end

    def y
        @y
    end
end

class Enemy_bullet
    attr_accessor :bullet_angle
    def initialize(x, y, player_x, player_y)
        @bullet_img = Gosu::Image.new("media/enemy_bullet.png")
        @x, @y = x, y+10
        @angle = degree(@x, @y, player_x, player_y)
        @bullet_angle = @angle

    end

    def draw(player_x, player_y)

        #追尾弾の時
        @angle = degree(@x, @y, player_x, player_y)
        if (@bullet_angle.abs - @angle.abs) <= -5 || (@bullet_angle.abs - @angle.abs) >= 5
            if @angle >= 0
                if @bullet_angle >= 0
                    @bullet_angle > @angle ? @bullet_angle -= 1 : @bullet_angle += 1
                else
                    @bullet_angle > (@angle - 180) ? @bullet_angle += 1 : @bullet_angle -=1
                end
            else
                if @bullet_angle < 0
                    @bullet_angle > @angle ? @bullet_angle -= 1 : @bullet_angle += 1
                else
                    @bullet_angle > (@angle + 180) ? @bullet_angle += 1: @bullet_angle -= 1
                end
            end
        end

        @vx = Math.cos(@bullet_angle * Math::PI / 180)
        @vy = Math.sin(@bullet_angle * Math::PI / 180)

        @x += @vx
        @y += @vy
        @bullet_img.draw_rot(@x, @y, 1, @bullet_angle+90)
    end

    def track_angle(bullet_x, bullet_y, player_x, player_y)
        degree(bullet_x, bullet_y, player_x, player_y)
    end

    def re_angle
        @angle
    end

    def bullet_angle
        @bullet_angle
    end

    def x
        @x
    end

    def y
        @y
    end

    def vx
        @vx
    end
    def vy
        @vy
    end
end

class Explosion
    def initialize(x,y)
        @x ,@y = x, y
        @img = Gosu::Image.new("media/explosion.png")
    end

    def draw
        @img.draw(@x,@y,1)
    end
end

class Back_image
    def initialize
        @bg_image = Gosu::Image.new("media/space2.png", tileable: true )
        @y = -600
    end

    def draw
        @y += 1
        @bg_image.draw(0,@y,0)
    end

    def y
        @y
    end
    
    def set_y(n)
        @y = n
    end
end

Invader.new.show