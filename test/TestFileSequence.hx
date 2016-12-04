import de.polygonal.core.tools.FileSequence;
import haxe.unit.TestCase;

class TestFileSequence extends TestCase 
{
	function test()
	{
		var sequences:Array<{name:String, items:Array<String>}> = [];
		
		sequences = new FileSequence().find(["a", "b"]);
		assertEquals(0, sequences.length);
		
		sequences = new FileSequence().find(["file_1_1", "file_1_2", "file_1_3"]);
		assertEquals(1, sequences.length);
		assertEquals(3, sequences[0].items.length);
		assertEquals("file_1_{counter}", sequences[0].name);
		assertEquals("file_1_1", sequences[0].items[0]);
		assertEquals("file_1_2", sequences[0].items[1]);
		assertEquals("file_1_3", sequences[0].items[2]);
		
		sequences = new FileSequence().find(["file_1", "file_2", "file_3"]);
		assertEquals(1, sequences.length);
		assertEquals(3, sequences[0].items.length);
		assertEquals("file_{counter}", sequences[0].name);
		assertEquals("file_1", sequences[0].items[0]);
		assertEquals("file_2", sequences[0].items[1]);
		assertEquals("file_3", sequences[0].items[2]);
		
		sequences = new FileSequence().find(["file_1", "file_2", "foo", "file_3", "file_5", "file_6"]);
		assertEquals(2, sequences.length);
		assertEquals(3, sequences[0].items.length);
		assertEquals(2, sequences[1].items.length);
		assertEquals("file_{counter}", sequences[0].name);
		assertEquals("file_{counter}", sequences[1].name);
		assertEquals("file_1", sequences[0].items[0]);
		assertEquals("file_2", sequences[0].items[1]);
		assertEquals("file_3", sequences[0].items[2]);
		assertEquals("file_5", sequences[1].items[0]);
		assertEquals("file_6", sequences[1].items[1]);
		
		sequences = new FileSequence().find(
			[
				"file_1_1.png",
				"file_2_2.png",
				"file_3_3.png",
				"file_4_4.png"
			]);
		assertEquals(0, sequences.length);
		
		sequences = new FileSequence().find(
			[
				"file_1_1.png",
				"file_2_2.png",
				"file_3_3.png",
				"file_4_4.png"
			]);
		assertEquals(0, sequences.length);
		
		sequences = new FileSequence().find(
			[
				"file_5_6_0004.png",
				"file_5_6_0002.png",
				"file_5_6_0003.png",
				"file_5_6_0001.png"
			]);
		assertEquals(1, sequences.length);
		assertEquals(4, sequences[0].items.length);
		assertEquals(4, sequences[0].items.length);
		assertEquals("file_5_6_{counter}.png", sequences[0].name);
		assertEquals("file_5_6_0002.png", sequences[0].items[1]);
		assertEquals("file_5_6_0003.png", sequences[0].items[2]);
		assertEquals("file_5_6_0004.png", sequences[0].items[3]);
		
		sequences = new FileSequence().find(
			[
				"file_5_6_0004.png",
				"file_5_6_0002.png",
				"file_5_6_0003.png",
				"file_5_6_0001.png",
				
				"file_5_6_0007.png",
				"file_5_6_0008.png",
				"file_5_6_0009.png",
				"file_5_6_0010.png"
			]);
		assertEquals(2, sequences.length);
		assertEquals(4, sequences[0].items.length);
		assertEquals("file_5_6_{counter}.png", sequences[0].name);
		assertEquals("file_5_6_0001.png", sequences[0].items[0]);
		assertEquals("file_5_6_0002.png", sequences[0].items[1]);
		assertEquals("file_5_6_0003.png", sequences[0].items[2]);
		assertEquals("file_5_6_0004.png", sequences[0].items[3]);
		assertEquals(4, sequences[1].items.length);
		assertEquals("file_5_6_{counter}.png", sequences[1].name);
		assertEquals("file_5_6_0007.png", sequences[1].items[0]);
		assertEquals("file_5_6_0008.png", sequences[1].items[1]);
		assertEquals("file_5_6_0009.png", sequences[1].items[2]);
		assertEquals("file_5_6_0010.png", sequences[1].items[3]);
		
		sequences = new FileSequence().find(
			[
				"file_5_1_007",
				"file_5_2_007",
				"file_5_3_007",
				"file_5_4_007",
			]);
		assertEquals(1, sequences.length);
		assertEquals(4, sequences[0].items.length);
		assertEquals("file_5_{counter}_007", sequences[0].name);
		assertEquals("file_5_1_007", sequences[0].items[0]);
		assertEquals("file_5_2_007", sequences[0].items[1]);
		assertEquals("file_5_3_007", sequences[0].items[2]);
		assertEquals("file_5_4_007", sequences[0].items[3]);
		
		sequences = new FileSequence().find(
			[
				"file_3_6_01",
				"file_4_6_01",
				"file_5_6_01",
				"file_6_6_01"
			]);
		assertEquals(1, sequences.length);
		assertEquals(4, sequences[0].items.length);
		assertEquals("file_{counter}_6_01", sequences[0].name);
		assertEquals("file_3_6_01", sequences[0].items[0]);
		assertEquals("file_4_6_01", sequences[0].items[1]);
		assertEquals("file_5_6_01", sequences[0].items[2]);
		assertEquals("file_6_6_01", sequences[0].items[3]);
		
		sequences = new FileSequence().find(
			[
				"a_001",
				"a_b_1_c_2",
				"a_003",
				"01_b_1",
				"01_b_3",
				"01_b_2",
				"a_b_1_c_0",
				"a_002",
				"a_b_1_c_1"
			]);
		
		assertEquals(3, sequences.length);
		assertEquals(3, sequences[0].items.length);
		assertEquals(3, sequences[1].items.length);
		assertEquals(3, sequences[2].items.length);
		assertEquals("a_b_1_c_{counter}", sequences[0].name);
		assertEquals("a_b_1_c_0", sequences[0].items[0]);
		assertEquals("a_b_1_c_1", sequences[0].items[1]);
		assertEquals("a_b_1_c_2", sequences[0].items[2]);
		assertEquals("01_b_{counter}", sequences[1].name);
		assertEquals("01_b_1", sequences[1].items[0]);
		assertEquals("01_b_2", sequences[1].items[1]);
		assertEquals("01_b_3", sequences[1].items[2]);
		assertEquals("a_{counter}", sequences[2].name);
		assertEquals("a_001", sequences[2].items[0]);
		assertEquals("a_002", sequences[2].items[1]);
		assertEquals("a_003", sequences[2].items[2]);
		
		sequences = new FileSequence().find(["file_9", "file_10"]);
		assertEquals(0, sequences.length);
		
		sequences = new FileSequence(true).find(["file_1_0", "file_2_0"]);
		assertEquals(0, sequences.length);
		
		sequences = new FileSequence().find(
			[
				"AUDIO_BIG_MATCH1",
				"AUDIO_HIT_BREAKABLE3",
				"AUDIO_BOUNCER_APPEAR4",
				"AUDIO_BIG_MATCH2",
				"AUDIO_EARN_STAR1",
				"AUDIO_BOUNCER_COLLIDE4",
				"AUDIO_BOUNCER_APPEAR3",
				"AUDIO_BIG_MATCH3",
				"AUDIO_HIT_BREAKABLE1",
				"AUDIO_BOUNCER_COLLIDE2",
				"AUDIO_BOUNCER_APPEAR2",
				"AUDIO_EARN_STAR3",
				"AUDIO_BOUNCER_COLLIDE1",
				"AUDIO_EARN_STAR2",
				"AUDIO_HIT_BREAKABLE2",
				"AUDIO_BOUNCER_DISAPPEAR",
				"AUDIO_BOUNCER_APPEAR1",
				"AUDIO_BOUNCER_COLLIDE3"
			]);
			
		assertEquals(5, sequences.length);
		assertEquals(4, sequences[0].items.length);
		assertEquals(4, sequences[1].items.length);
		assertEquals(3, sequences[2].items.length);
		assertEquals(3, sequences[3].items.length);
		assertEquals(3, sequences[4].items.length);
		
		assertEquals("AUDIO_BOUNCER_APPEAR{counter}", sequences[0].name);
		assertEquals("AUDIO_BOUNCER_COLLIDE{counter}", sequences[1].name);
		assertEquals("AUDIO_HIT_BREAKABLE{counter}", sequences[2].name);
		assertEquals("AUDIO_EARN_STAR{counter}", sequences[3].name);
		assertEquals("AUDIO_BIG_MATCH{counter}", sequences[4].name);
		
		for (i in 0...4) assertEquals("AUDIO_BOUNCER_APPEAR" + (i + 1), sequences[0].items[i]);
		for (i in 0...4) assertEquals("AUDIO_BOUNCER_COLLIDE" + (i + 1), sequences[1].items[i]);
		for (i in 0...3) assertEquals("AUDIO_HIT_BREAKABLE" + (i + 1), sequences[2].items[i]);
		for (i in 0...3) assertEquals("AUDIO_EARN_STAR" + (i + 1), sequences[3].items[i]);
		for (i in 0...3) assertEquals("AUDIO_BIG_MATCH" + (i + 1), sequences[4].items[i]);
	}
	
	@:access(de.polygonal.core.tools.FileSequence)
	function testAssignHelper()
	{
		var fileSequence = new FileSequence();
		
		var cmp = function(a, b) return a == b;
		var o;
		
		var assign = fileSequence.assign;
		
		o = assign([], cmp);
		assertEquals(0, o.length);
		
		o = assign([0], cmp);
		assertEquals(0, o.length);
		
		o = assign([0, 1], cmp);
		assertEquals(0, o.length);
		
		o = assign([0, 1, 2], cmp);
		assertEquals(0, o.length);
		
		o = assign([1, 1], cmp);
		assertEquals(1, o.length);
		assertEquals(2, o[0].length);
		assertEquals(1, o[0][0]);
		assertEquals(1, o[0][1]);
		
		o = assign([1, 2, 1], cmp);
		assertEquals(1, o.length);
		assertEquals(2, o[0].length);
		assertEquals(1, o[0][0]);
		assertEquals(1, o[0][1]);
		
		o = assign([1, 1, 2], cmp);
		assertEquals(1, o.length);
		assertEquals(2, o[0].length);
		assertEquals(1, o[0][0]);
		assertEquals(1, o[0][1]);
		
		o = assign([2, 2, 1, 1], cmp);
		assertEquals(2, o.length);
		assertEquals(2, o[0].length);
		assertEquals(2, o[1].length);
		assertEquals(1, o[0][0]);
		assertEquals(1, o[0][1]);
		assertEquals(2, o[1][0]);
		assertEquals(2, o[1][1]);
		
		o = assign([0, 2, 1, 2], cmp);
		assertEquals(1, o.length);
		assertEquals(2, o[0].length);
		assertEquals(2, o[0][0]);
		assertEquals(2, o[0][1]);
	}
}
