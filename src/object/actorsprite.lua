local ActorSprite, super = Class(Sprite)

function ActorSprite:init(actor)
    self.actor = actor
    self.sprite = nil
    self.full_sprite = nil
    self.anim = nil
    self.facing = "down"
    self.last_facing = "down"

    self.directional = false
    self.dir_sep = "_"

    super:init(self, actor.default or "", 0, 0, actor.width, actor.height, actor.path)

    self.default_anim = actor.default_anim
    if self.default_anim then
        self:setAnimation(self.default_anim)
    end

    self.offsets = actor.offsets or {}

    self.walking = false
    self.walk_speed = 4
    self.walk_frame = 1
end

function ActorSprite:setCustomSprite(texture, ox, oy, keep_anim)
    self.path = ""
    if ox and oy then
        self.force_offset = {ox, oy}
    else
        self.force_offset = nil
    end
    self:_setSprite(texture, keep_anim)
end

function ActorSprite:setSprite(texture, keep_anim)
    self.path = self.actor.path or ""
    self.force_offset = nil
    self:_setSprite(texture, keep_anim)
end

function ActorSprite:_setSprite(texture, keep_anim)
    if type(texture) ~= "string" then
        error("Texture must be a string")
    end

    if not keep_anim then
        self.anim = nil
    end

    self.sprite = texture
    self.full_sprite = self:getPath(texture)
    self.directional, self.dir_sep = self:isDirectional(self.full_sprite)

    if self.directional then
        super:setSprite(self, self.sprite..self.dir_sep..self.facing, keep_anim)
    else
        self.walk_frame = 1
        super:setSprite(self, self.sprite, keep_anim)
    end
end

function ActorSprite:setAnimation(anim, callback)
    local last_anim = self.anim
    local last_sprite = self.sprite
    self.anim = anim
    if type(anim) == "string" then
        anim = self.actor.animations[anim]
    end
    if anim then
        if anim.next then
            if self.actor.animations[anim.next] then
                anim.callback = function(s) s:setAnimation(anim.next) end
            else
                anim.callback = function(s) s:setSprite(anim.next) end
            end
        elseif anim.temp then
            if last_anim then
                anim.callback = function(s) s:setAnimation(last_anim) end
            elseif last_sprite then
                anim.callback = function(s) s:setSprite(last_sprite) end
            end
        end
        if callback then
            if anim.callback then
                local old_callback = anim.callback
                anim.callback = function(s) old_callback(); callback(s) end
            else
                anim.callback = callback
            end
        end
        super:setAnimation(self, anim)
        return true
    else
        if callback then
            callback(self)
        end
        return false
    end
end

function ActorSprite:updateDirection()
    if self.directional and self.last_facing ~= self.facing then
        super:setSprite(self, self.sprite..self.dir_sep..self.facing, true)
    end
    self.last_facing = self.facing
end

function ActorSprite:isDirectional(texture)
    if Assets.getTexture(texture.."_left") or Assets.getFrames(texture.."_left") then
        return true, "_"
    elseif Assets.getTexture(texture.."/left") or Assets.getFrames(texture.."/left") then
        return true, "/"
    end
end

function ActorSprite:getOffset()
    if self.force_offset then
        return self.force_offset
    end
    local frames_for = Assets.getFramesFor(self.full_sprite)
    local frames_for_dir = self.directional and Assets.getFramesFor(self.full_sprite..self.dir_sep..self.facing)
    return self.offsets[self.sprite] or (frames_for and self.offsets[frames_for]) or
            (self.directional and (self.offsets[self.sprite..self.dir_sep..self.facing] or (frames_for_dir and self.offsets[frames_for_dir])))
            or {0, 0}
end

function ActorSprite:update(dt)
    if not self.playing then
        local floored_frame = math.floor(self.walk_frame)
        if floored_frame ~= self.walk_frame or (self.directional and self.walking) then
            self.walk_frame = Utils.approach(self.walk_frame, floored_frame + 1, dt * (self.walk_speed > 0 and self.walk_speed or 1))
            self:setFrame(floored_frame)
        elseif self.directional and self.frames and not self.walking then
            self:setFrame(1)
        end

        self:updateDirection()
    end

    super:update(self, dt)
end

function ActorSprite:createTransform()
    local transform = super:createTransform(self)
    local offset = self:getOffset()
    transform:translate(-offset[1], -offset[2])
    return transform
end

return ActorSprite