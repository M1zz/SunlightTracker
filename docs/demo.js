// 햇빛바라기 웹 데모: 밝기와 시간을 골라 햇빛을 모으고 해바라기에게 준다.
// 규칙은 앱과 같다. 실외 판정 300 Lux (AppSettings.outdoorThresholdLux),
// 모은 햇빛 = 분 × Lux ÷ 3000, 한 번에 최대 100 (SunlightManager.calculateChargeAmount),
// 에너지는 시간당 2.5 줄고 (SunflowerHealth.decayRatePerHour) 80·50·20 에서 상태가 바뀐다 (healthState).
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);
  const lang = document.documentElement.lang;
  const LUX = [200, 800, 3000, 12000];  // 앱의 밝기 구간(약한 빛 · 실외/흐림 · 햇빛 · 강한 햇빛)마다 예시 값 하나
  const OUTDOOR = 300, DAY_DECAY = 2.5 * 24;
  const s = { place: 2, minutes: 20, battery: 0, energy: 35 };
  const num = n => Math.round(n).toLocaleString(lang);
  const gain = () => LUX[s.place] < OUTDOOR ? 0 : Math.min(100, s.minutes * LUX[s.place] / 3000);
  const state = e => e >= 80 ? 0 : e >= 50 ? 1 : e >= 20 ? 2 : 3;

  const petals = Array.from({ length: 12 }, (_, i) =>
    `<ellipse cx="0" cy="-40" rx="13" ry="30" transform="rotate(${i * 30})"/>`).join("");
  root.innerHTML = `
    <div class="sun-stage">
      <svg class="sun-flower" viewBox="0 0 200 230" aria-hidden="true">
        <path class="stem" d="M100 120 C 98 160, 104 190, 100 228"/>
        <path class="leaf" d="M101 182 C 120 160, 145 162, 150 170 C 138 186, 118 190, 101 182 Z"/>
        <g class="head"><g class="petals">${petals}</g>
          <circle r="31" class="disc"/><circle cx="-10" cy="-5" r="3.5" class="eye"/><circle cx="10" cy="-5" r="3.5" class="eye"/>
          <path class="mouth" d="M-11 9 Q0 18 11 9"/></g>
      </svg>
      <p class="sun-state" aria-live="polite"></p>
      <div class="sun-bar" aria-hidden="true"><i></i></div>
    </div>
    <div class="sun-controls">
      <div class="sun-places" role="group">
        ${T.places.map((p, i) => `<button type="button" class="chip" data-place="${i}" aria-pressed="false">${p}<small>${num(LUX[i])} Lux</small></button>`).join("")}
      </div>
      <label class="sun-time"><span class="sun-row"><span></span><b class="sun-gain" aria-live="polite"></b></span>
        <input type="range" min="5" max="60" step="5" value="${s.minutes}"></label>
      <p class="sun-none muted small" aria-live="polite"></p>
      <div class="sun-battery"><span></span><div class="sun-bar"><i></i></div></div>
      <div class="sun-actions">
        <button type="button" class="act" data-do="go">${T.go}</button>
        <button type="button" class="act" data-do="give">${T.give}</button>
        <button type="button" class="act ghost" data-do="day">${T.day}</button>
      </div>
      <p class="muted small">${T.note}</p>
    </div>`;

  const $ = q => root.querySelector(q);
  const head = $(".head"), range = $("input");
  function render() {
    const e = s.energy, st = state(e), g = gain();
    root.querySelectorAll("[data-place]").forEach(b => b.setAttribute("aria-pressed", String(+b.dataset.place === s.place)));
    $(".sun-row span").textContent = T.minutes.replace("{n}", s.minutes);
    range.setAttribute("aria-valuetext", T.minutes.replace("{n}", s.minutes));
    $(".sun-gain").textContent = `+${num(g)}%`;
    $(".sun-none").textContent = g > 0 ? "" : T.none;
    $(".sun-battery span").textContent = `⚡ ${T.gain} ${num(s.battery)}%`;
    $(".sun-battery i").style.width = `${s.battery}%`;
    $(".sun-state").textContent = `${T.states[st]} · ${T.energy} ${num(e)}%`;
    $(".sun-stage .sun-bar i").style.width = `${e}%`;
    $(".sun-stage").dataset.state = st;
    // 에너지가 줄수록 고개를 숙이고 색이 바랜다.
    const droop = (1 - e / 100) * 38;
    head.style.transform = `translate(100px, 120px) rotate(${droop}deg) translate(0, -34px) scale(${0.82 + e / 550})`;
    head.style.filter = `saturate(${0.3 + e / 140})`;
    $(".mouth").setAttribute("d", st < 2 ? "M-11 9 Q0 18 11 9" : st === 2 ? "M-10 12 L10 12" : "M-11 15 Q0 6 11 15");
    $('[data-do="give"]').disabled = s.battery <= 0;
    $('[data-do="go"]').disabled = g <= 0;
  }
  root.addEventListener("click", e => {
    const b = e.target.closest("button");
    if (!b) return;
    if (b.dataset.place) s.place = +b.dataset.place;
    if (b.dataset.do === "go") s.battery = Math.min(100, s.battery + gain());
    if (b.dataset.do === "give") { s.energy = Math.min(100, s.energy + s.battery); s.battery = 0; }
    if (b.dataset.do === "day") s.energy = Math.max(0, s.energy - DAY_DECAY);
    render();
  });
  range.addEventListener("input", () => { s.minutes = +range.value; render(); });
  render();
})();
