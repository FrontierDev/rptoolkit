local CTAuraEffect = {}
_G.AuraEffect = CTAuraEffect

-- Deals damage to [target].
function AuraEffect:DamageTick(target, aura, effect)
    local sender = string.format("%s's %s", UnitName("player"), aura.Name)
    Targeting:ApplyDamage(sender, target, tonumber(effect.Value), effect.School, "AURA")
end

-- Heals the [target]
function AuraEffect:HealingTick(target, aura, effect)
    local sender = string.format("%s's %s", UnitName("player"), aura.Name)
    Targeting:ApplyHealing(sender, target, tonumber(effect.Value), "AURA")
end