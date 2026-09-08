(function () {
    "use strict";

    var UPDATE_INTERVAL = 0.05;
    var NET_TABLE = "tag_cursed_ui";

    var lastDebugState = null;
    var missingAbilitiesLogged = false;
    function GetHudRoot() {
        var panel = $.GetContextPanel();

        while (panel && panel.GetParent()) {
            panel = panel.GetParent();
        }

        return panel;
    }

    function FindDotaHudElement(id) {
        var root = GetHudRoot();

        if (!root) {
            return null;
        }

        return root.FindChildTraverse(id);
    }

    function GetLocalFearUiState() {
        var playerID = Players.GetLocalPlayer();

        if (
            playerID === -1 ||
            playerID === undefined
        ) {
            return null;
        }

        return CustomNetTables.GetTableValue(
            NET_TABLE,
            String(playerID)
        );
    }

    function SetAbilityImageFearLocked(
        abilityPanel,
        locked
    ) {
        if (!abilityPanel) {
            return false;
        }

        var image =
            abilityPanel.FindChildTraverse(
                "AbilityImage"
            );

        if (!image) {
            return false;
        }

        // Keep cooldown radial/text untouched. Only the actual spell artwork
        // becomes grey, so Fear affordability remains readable during CD.
        image.style.saturation = locked ? "0.30" : "1.0";

        image.style.brightness = locked ? "0.62" : "1.0";

        image.style.washColor = locked ? "#E34848FF" : "#FFFFFFFF";

        return true;
    }

    function RestoreCursedAbilityImages(
        abilitiesPanel
    ) {
        if (!abilitiesPanel) {
            return;
        }

        var children = abilitiesPanel.Children();

        for (var i = 0; i < children.length; ++i) {
            var image =
                children[i].FindChildTraverse(
                    "AbilityImage"
                );

            if (!image) {
                continue;
            }

            var ability =
                image.contextEntityIndex;

            if (
                ability === -1 ||
                ability === undefined
            ) {
                continue;
            }

            var name =
                Abilities.GetAbilityName(ability);

            if (
                name === "tag_cursed_dread_presence" ||
                name === "tag_cursed_curse_wave"
            ) {
                SetAbilityImageFearLocked(
                    children[i],
                    false
                );
            }
        }
    }

    function ApplyFearPresentation() {
        var abilitiesPanel =
            FindDotaHudElement("abilities");

        var fearUi =
            GetLocalFearUiState();

        if (!abilitiesPanel || !fearUi) {
            return;
        }

        var children = abilitiesPanel.Children();

        for (var i = 0; i < children.length; ++i) {
            var abilityPanel = children[i];

            var image =
                abilityPanel.FindChildTraverse(
                    "AbilityImage"
                );

            if (!image) {
                continue;
            }

            var ability =
                image.contextEntityIndex;

            if (
                ability === -1 ||
                ability === undefined
            ) {
                continue;
            }

            var name =
                Abilities.GetAbilityName(ability);

            if (
                name === "tag_cursed_dread_presence"
            ) {
                SetAbilityImageFearLocked(
                    abilityPanel,
                    fearUi.q_fear_locked === 1
                );
            } else if (
                name === "tag_cursed_curse_wave"
            ) {
                SetAbilityImageFearLocked(
                    abilityPanel,
                    fearUi.w_fear_locked === 1
                );
            }
        }
    }

    function ShowHudError(message) {
        GameEvents.SendEventClientSide(
            "dota_hud_error_message",
            {
                splitscreenplayer: 0,
                reason: 80,
                message: message
            }
        );

        Game.EmitSound("General.Cancel");
    }

    function Think() {
        ApplyFearPresentation();

        $.Schedule(
            UPDATE_INTERVAL,
            Think
        );
    }
    Think();
})();
