local Outline, super = Class(Event)

function Outline:init(data)
    super:init(self, data.x, data.y, data.width, data.height)

    self.solid = false

    self:setOrigin(0, 0)
    self:setHitbox(0, 0, data.width, data.height)

    self.canvas = love.graphics.newCanvas(data.width, data.height)

    self.shader = love.graphics.newShader([[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
           if (Texel(texture, texture_coords).a == 0) {
              // a discarded pixel wont be applied as the stencil.
              discard;
           }
           return vec4(1.0);
        }
    ]])
end

function Outline:drawCharacter(object)
    love.graphics.push()
    object:preDraw()
    object:draw()
    object:postDraw()
    love.graphics.pop()
end

function Outline:drawMask(object)
    love.graphics.setShader(self.shader)
    self:drawCharacter(object)
    love.graphics.setShader()
end

function Outline:draw()
    super:draw(self)

    Draw.pushCanvas(self.canvas)
    love.graphics.clear()

    love.graphics.translate(-self.x, -self.y)

    for _, object in ipairs(Game.world.children) do
        if object:includes(Character) then
            love.graphics.stencil((function() self:drawMask(object) end), "replace", 1)
            love.graphics.setStencilTest("less", 1)

            love.graphics.setShader(Kristal.Shaders["AddColor"])

            local color = object.actor.color
            if not color then
                color = {1, 0, 0, 1}
            end

            Kristal.Shaders["AddColor"]:send("inputcolor", color)
            Kristal.Shaders["AddColor"]:send("amount", 1)

            love.graphics.translate(-2, 0)
            self:drawCharacter(object)
            love.graphics.translate(2, 0)

            love.graphics.translate(2, 0)
            self:drawCharacter(object)
            love.graphics.translate(-2, 0)

            love.graphics.translate(0, 2)
            self:drawCharacter(object)
            love.graphics.translate(0, -2)

            love.graphics.translate(0, -2)
            self:drawCharacter(object)
            love.graphics.translate(0, 2)

            love.graphics.setShader()

            love.graphics.setStencilTest()
        end
    end

    Draw.popCanvas()

    love.graphics.draw(self.canvas)
end

return Outline