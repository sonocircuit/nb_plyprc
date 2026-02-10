// polyperc (voice limited + mod section) - nb editon v.1.0 @sonoCircuit

NB_plyprc {

	*initClass {

		var synthParams, synthGroup, synthVoices;
		var numVoices = 6;

		StartUp.add {

			var s = Server.default;

			synthParams = Dictionary.newFrom([
				\amp, 0.8,
				\spread, 0,
				\sendA, 0,
				\sendB, 0,
				\pw, 0.5,
				\decay, 1.2,
				\cutoff_lpf, 1200,
				\res_lpf, 0.1,
				\track_lpf, 0,
				\mod_depth, 0,
				\pw_mod, 0,
				\cut_mod, 0,
				\sendA_mod, 0,
				\sendB_mod, 0
			]);

			synthVoices = Array.newClear(numVoices);

			OSCFunc.new({ |msg|
				if (synthGroup.isNil) {

					synthGroup = Group.new(s);

					SynthDef(\nb_plyprc,{
						arg out = 0, sendABus = 0, sendBBus = 0,
						freq = 110, vel = 1, gate = 1, decay = 1.2,
						amp = 1.0, spread = 0, sendA = 0, sendB = 0,
						pw = 0.5,  cutoff_lpf = 1200, res_lpf = 0.1, track_lpf = 0,
						pw_mod = 0, cut_mod = 0, sendA_mod = 0, sendB_mod = 0, mod_depth = 0;

						var env, cut, res, cut_lin_lpf, cut_lpf_mod, snd;

						env = EnvGen.kr(Env.perc(0, decay), gate, doneAction: 2);

						sendA = Lag.kr(sendA + (sendA_mod * mod_depth)).clip(0, 1);
						sendB = Lag.kr(sendB + (sendA_mod * mod_depth)).clip(0, 1);
						pw = Lag.kr(pw + (pw_mod * mod_depth)).clip(0.02, 0.98);
						cut = Lag.kr((cutoff_lpf.cpsmidi + (cut_mod * 127 * mod_depth) + (track_lpf * freq.cpsmidi)).midicps).clip(20, 20000);
						res = Lag.kr(res_lpf.linlin(0, 1, 0, 4));

						snd = Pulse.ar(freq, pw);
						snd = MoogFF.ar(snd, cut, res) * env * amp * vel * vel;
						snd = Pan2.ar(snd, spread * Rand(-0.7, 0.7));

						Out.ar(out, snd);
						Out.ar(sendABus, sendA * snd);
						Out.ar(sendBBus, sendB * snd);
					}).add;

					"nb plyprc initialized".postln;
				};
			}, "/nb_plyprc/init");

			OSCFunc.new({ |msg|
				var vox = msg[1].asInteger;
				var freq = msg[2].asFloat;
				var vel = msg[3].asFloat;
				var syn;
				if (synthGroup.notNil) {
					if (synthVoices[vox].notNil) { synthVoices[vox].set(\gate, -1.05) };
					syn = Synth.new(\nb_plyprc,
						[
							\freq, freq,
							\vel, vel,
							\sendABus, ~sendA ? s.outputBus,
							\sendBBus, ~sendB ? s.outputBus,
						] ++ synthParams.getPairs, target: synthGroup
					);
					synthVoices[vox] = syn;
					syn.onFree({ if(synthVoices[vox] === syn) {synthVoices[vox] = nil} });
				};
			}, "/nb_plyprc/trig");

			OSCFunc.new({ |msg|
				var key = msg[1].asSymbol;
				var val = msg[2].asFloat;
				if (synthGroup.notNil) {
					synthGroup.set(key, val);
				};
				synthParams[key] = val;
			}, "/nb_plyprc/set_param");

			OSCFunc.new({ |msg|
				if (synthGroup.notNil) {
					synthGroup.set(\gate, -1.05);
				};
			}, "/nb_plyprc/panic");

			OSCFunc.new({ |msg|
				if (synthGroup.notNil) {
					synthGroup.free;
					synthGroup = nil;
					numVoices.do({ arg vox;
						synthVoices[vox] = nil
					});
					"nb plyprc removed".postln;
				};
			}, "/nb_plyprc/free");

		}
	}
}