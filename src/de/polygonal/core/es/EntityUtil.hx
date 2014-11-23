package de.polygonal.core.es;

class EntityUtil
{
	/**
		Pretty-prints the entity hierarchy starting at `root`.
	**/
	public static function prettyPrint(root:Entity):String
	{
		if (root == null) return root.toString();
		
		function depth(x:Entity):Int
		{
			if (x.parent == null) return 0;
			var e = x;
			var c = 0;
			while (e.parent != null)
			{
				c++;
				e = e.parent;
			}
			return c;
		}	
		
		var s = root.name + '\n';
		
		var a = [root];
		
		var e = root.preorder;
		while (e != null)
		{
			a.push(e);
			
			e = e.preorder;
		}
		
		for (e in a)
		{
			var d = depth(e);
			for (i in 0...d)
			{
				if (i == d - 1)
					s += "+--- ";
				else
					s += "|    ";
			}
			s += "" + e.name + "\n";
		}
		
		return s;
	}
}