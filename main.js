import * as THREE from 'https://cdn.skypack.dev/three@0.136';

import {RGBELoader} from 'https://cdn.skypack.dev/three@0.136/examples/jsm/loaders/RGBELoader.js';
import {OrbitControls} from 'https://cdn.skypack.dev/three@0.136/examples/jsm/controls/OrbitControls.js';


class WaveJS {
  constructor() {
  }

  async initialize() {
    this.renderer_ = new THREE.WebGLRenderer({ antialias: true });
    document.body.appendChild(this.renderer_.domElement);

    window.addEventListener('resize', () => {
      this.onWindowResize_();
    }, false);

    this.scene_ = new THREE.Scene();

    this.camera_ = new THREE.PerspectiveCamera(60, 1920.0 / 1080.0, 0.1, 2000.0);
    this.camera_.position.set(0, 0, -10);

    const controls = new OrbitControls(this.camera_, this.renderer_.domElement);
    controls.target.set(0, 1, 0);
    controls.update();

    await this.setLightning_();
    await this.createWavePlane_();


    this.onWindowResize_();

    this.totalTime_ = 0.0;
    this.previousRAF_ = null;
    this.raf_();
  }

  async setLightning_() {
        var envmap = new RGBELoader().load( './resources/sky.hdr', function(texture){
            texture.mapping = THREE.EquirectangularReflectionMapping;
        });
        this.scene_.background = envmap;
        this.scene_.environment = envmap;

        this.renderer_.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer_.toneMappingExposure =1;
  }

  async createWavePlane_() {
    const vsh = await fetch('./shaders/gerstner_vs.glsl');
    const fsh = await fetch('./shaders/gerstner_ps.glsl');

    const material = new THREE.ShaderMaterial({
      uniforms: {
        time: {
          value: 0.0,
        }
      },
      vertexShader: await vsh.text(),
      fragmentShader: await fsh.text()
    });

    this.waveMaterial_ = material;

    var geometry = new THREE.PlaneGeometry( 1000, 1000, 1000, 1000 );
    var plane = new THREE.Mesh(geometry, material);
    plane.rotation.x = -Math.PI / 2;
    this.scene_.add(plane);
  }

  onWindowResize_() {
    this.camera_.aspect = window.innerWidth / window.innerHeight;
    this.camera_.updateProjectionMatrix();

    this.renderer_.setSize(window.innerWidth, window.innerHeight);
  }

  raf_() {
    requestAnimationFrame((t) => {
      if (this.previousRAF_ === null) {
        this.previousRAF_ = t;
      }

      this.step_(t - this.previousRAF_);
      this.renderer_.render(this.scene_, this.camera_);
      this.raf_();
      this.previousRAF_ = t;
    });
  }

  step_(timeElapsed) {
    const secondsElapsed = timeElapsed * 0.001;
    this.totalTime_ += secondsElapsed;

    this.waveMaterial_.uniforms.time.value = this.totalTime_;
  }
}


let APP_ = null;

window.addEventListener('DOMContentLoaded', async () => {
  APP_ = new WaveJS();
  await APP_.initialize();
});
