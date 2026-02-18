(function () {
    'use strict';

    // -------------------------------------------------------
    // TARGET ZONE MINIGAME
    // A circular gauge with a rotating indicator needle.
    // Player clicks/presses space to stop the needle.
    // Result: green (perfect), yellow (ok), red (miss).
    // -------------------------------------------------------

    const canvas = document.getElementById('minigame-canvas');
    const ctx = canvas.getContext('2d');
    const container = document.getElementById('minigame-container');

    const SIZE = 300;
    const CENTER = SIZE / 2;
    const OUTER_RADIUS = 130;
    const INNER_RADIUS = 90;
    const NEEDLE_LENGTH = OUTER_RADIUS + 10;

    let active = false;
    let animFrame = null;
    let callbackEvent = 'minigameResult'; // default NUI callback name

    // Game state
    let needleAngle = 0;       // current needle position in degrees
    let speed = 2.0;           // degrees per frame
    let greenStart = 0;        // degrees
    let greenSize = 45;        // degrees of arc
    let yellowSize = 30;       // degrees of arc on each side of green

    // -------------------------------------------------------
    // DRAWING
    // -------------------------------------------------------

    function degToRad(deg) {
        return (deg - 90) * (Math.PI / 180); // -90 so 0° is top
    }

    function drawArc(startDeg, endDeg, color) {
        ctx.beginPath();
        ctx.arc(CENTER, CENTER, OUTER_RADIUS, degToRad(startDeg), degToRad(endDeg));
        ctx.arc(CENTER, CENTER, INNER_RADIUS, degToRad(endDeg), degToRad(startDeg), true);
        ctx.closePath();
        ctx.fillStyle = color;
        ctx.fill();
    }

    function drawGauge() {
        ctx.clearRect(0, 0, SIZE, SIZE);

        // Background ring (red/miss zone)
        drawArc(0, 360, 'rgba(180, 40, 40, 0.7)');

        // Yellow zones (each side of green)
        const yellowLeftStart = greenStart - yellowSize;
        const yellowRightEnd = greenStart + greenSize + yellowSize;
        drawArc(yellowLeftStart, greenStart, 'rgba(200, 180, 50, 0.75)');
        drawArc(greenStart + greenSize, yellowRightEnd, 'rgba(200, 180, 50, 0.75)');

        // Green zone (target)
        drawArc(greenStart, greenStart + greenSize, 'rgba(50, 180, 70, 0.85)');

        // Center circle
        ctx.beginPath();
        ctx.arc(CENTER, CENTER, INNER_RADIUS - 2, 0, Math.PI * 2);
        ctx.fillStyle = 'rgba(20, 20, 25, 0.9)';
        ctx.fill();

        // Inner ring border
        ctx.beginPath();
        ctx.arc(CENTER, CENTER, INNER_RADIUS, 0, Math.PI * 2);
        ctx.strokeStyle = 'rgba(200, 200, 200, 0.3)';
        ctx.lineWidth = 2;
        ctx.stroke();

        // Outer ring border
        ctx.beginPath();
        ctx.arc(CENTER, CENTER, OUTER_RADIUS, 0, Math.PI * 2);
        ctx.strokeStyle = 'rgba(200, 200, 200, 0.3)';
        ctx.lineWidth = 2;
        ctx.stroke();
    }

    function drawNeedle(angle) {
        const rad = degToRad(angle);
        const endX = CENTER + Math.cos(rad) * NEEDLE_LENGTH;
        const endY = CENTER + Math.sin(rad) * NEEDLE_LENGTH;

        // Needle line
        ctx.beginPath();
        ctx.moveTo(CENTER, CENTER);
        ctx.lineTo(endX, endY);
        ctx.strokeStyle = '#ffffff';
        ctx.lineWidth = 3;
        ctx.lineCap = 'round';
        ctx.stroke();

        // Needle tip glow
        ctx.beginPath();
        ctx.arc(endX, endY, 5, 0, Math.PI * 2);
        ctx.fillStyle = '#ffffff';
        ctx.shadowColor = '#ffffff';
        ctx.shadowBlur = 12;
        ctx.fill();
        ctx.shadowBlur = 0;

        // Center dot
        ctx.beginPath();
        ctx.arc(CENTER, CENTER, 6, 0, Math.PI * 2);
        ctx.fillStyle = '#cccccc';
        ctx.fill();
    }

    // -------------------------------------------------------
    // GAME LOOP
    // -------------------------------------------------------

    function gameLoop() {
        if (!active) return;

        needleAngle = (needleAngle + speed) % 360;

        drawGauge();
        drawNeedle(needleAngle);

        animFrame = requestAnimationFrame(gameLoop);
    }

    // -------------------------------------------------------
    // RESULT CALCULATION
    // -------------------------------------------------------

    function getResult(angle) {
        // Normalize angle to 0-360
        const a = ((angle % 360) + 360) % 360;

        // Check green zone
        let gStart = ((greenStart % 360) + 360) % 360;

        if (isInArc(a, gStart, greenSize)) {
            return 'green';
        }

        // Check yellow zones
        let yLeftStart = (((greenStart - yellowSize) % 360) + 360) % 360;
        if (isInArc(a, yLeftStart, yellowSize)) {
            return 'yellow';
        }

        let yRightStart = ((greenStart + greenSize) % 360 + 360) % 360;
        if (isInArc(a, yRightStart, yellowSize)) {
            return 'yellow';
        }

        return 'red';
    }

    function isInArc(angle, start, size) {
        if (size <= 0) return false;
        if (size >= 360) return true;

        let end_ = (start + size) % 360;

        if (start < end_) {
            return angle >= start && angle < end_;
        } else {
            // Wraps around 360
            return angle >= start || angle < end_;
        }
    }

    // -------------------------------------------------------
    // INPUT HANDLING
    // -------------------------------------------------------

    function handleInput() {
        if (!active) return;

        active = false;
        if (animFrame) {
            cancelAnimationFrame(animFrame);
            animFrame = null;
        }

        const result = getResult(needleAngle);

        // Flash result color
        showResultFlash(result);

        // Send result after brief delay for visual feedback
        setTimeout(function () {
            container.classList.add('hidden');
            fetch('https://free-mining/' + callbackEvent, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ result: result }),
            });
        }, 600);
    }

    function showResultFlash(result) {
        const colors = {
            green: 'rgba(50, 220, 80, 0.4)',
            yellow: 'rgba(220, 200, 50, 0.4)',
            red: 'rgba(220, 50, 50, 0.4)',
        };

        // Draw final state with flash
        drawGauge();
        drawNeedle(needleAngle);

        ctx.beginPath();
        ctx.arc(CENTER, CENTER, OUTER_RADIUS, 0, Math.PI * 2);
        ctx.fillStyle = colors[result] || colors.red;
        ctx.fill();

        // Redraw needle on top
        drawNeedle(needleAngle);
    }

    // Click handler
    canvas.addEventListener('click', function (e) {
        e.preventDefault();
        handleInput();
    });

    // Keyboard handler
    document.addEventListener('keydown', function (e) {
        if (e.code === 'Space' && active) {
            e.preventDefault();
            handleInput();
        }
        // Escape to cancel
        if (e.code === 'Escape' && active) {
            e.preventDefault();
            active = false;
            if (animFrame) {
                cancelAnimationFrame(animFrame);
                animFrame = null;
            }
            container.classList.add('hidden');
            fetch('https://free-mining/minigameClose', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({}),
            });
        }
    });

    // -------------------------------------------------------
    // NUI MESSAGE HANDLER
    // -------------------------------------------------------

    window.addEventListener('message', function (event) {
        const data = event.data;

        if (data.action === 'startMinigame') {
            greenSize = data.greenZone || 45;
            yellowSize = data.yellowZone || 30;
            speed = data.speed || 2.0;
            callbackEvent = data.callbackEvent || 'minigameResult';

            // Randomize green zone position each time
            greenStart = Math.floor(Math.random() * 360);

            // Reset needle to opposite side of green zone for fairness
            needleAngle = (greenStart + 180) % 360;

            active = true;
            container.classList.remove('hidden');
            gameLoop();
        }
    });
})();
