const Map<String, Map<String, String>> wordRoots = {
  // Common prefixes
  'un': {'meaning': '不，非', 'example': 'unable, unhappy, unfair'},
  're': {'meaning': '再，重新', 'example': 'review, return, rebuild'},
  'in': {'meaning': '不，进入', 'example': 'incorrect, include, indoor'},
  'im': {'meaning': '不，进入', 'example': 'impossible, import, improve'},
  'dis': {'meaning': '不，分离', 'example': 'disagree, discover, dislike'},
  'en': {'meaning': '使成为', 'example': 'enable, enjoy, encourage'},
  'em': {'meaning': '使成为', 'example': 'empower, embrace, employ'},
  'non': {'meaning': '不，非', 'example': 'nonsense, nonprofit, nonstop'},
  'pre': {'meaning': '预先，在前', 'example': 'preview, predict, prepare'},
  'post': {'meaning': '在后', 'example': 'postpone, postgraduate'},
  'anti': {'meaning': '反对，防止', 'example': 'antibody, antivirus'},
  'auto': {'meaning': '自动', 'example': 'automatic, automobile'},
  'bi': {'meaning': '二，双', 'example': 'bicycle, bilingual'},
  'co': {'meaning': '共同', 'example': 'cooperate, coexist'},
  'com': {'meaning': '共同', 'example': 'company, compare, combine'},
  'con': {'meaning': '共同', 'example': 'connect, consider, control'},
  'de': {'meaning': '向下，去除', 'example': 'decrease, depart, define'},
  'ex': {'meaning': '出，前', 'example': 'export, exit, exchange'},
  'extra': {'meaning': '超出', 'example': 'extraordinary, extreme'},
  'hyper': {'meaning': '过度', 'example': 'hyperactive, hypertension'},
  'inter': {'meaning': '之间', 'example': 'international, interact'},
  'mis': {'meaning': '错误', 'example': 'mistake, misunderstand'},
  'mono': {'meaning': '单一', 'example': 'monopoly, monologue'},
  'multi': {'meaning': '多', 'example': 'multiply, multimedia'},
  'over': {'meaning': '过度，超过', 'example': 'overcome, overlook'},
  'out': {'meaning': '出，超过', 'example': 'output, outstanding'},
  'poly': {'meaning': '多', 'example': 'polygon, polyglot'},
  'sub': {'meaning': '下，次', 'example': 'subway, submarine'},
  'super': {'meaning': '超，上', 'example': 'supermarket, superior'},
  'trans': {'meaning': '跨越', 'example': 'transfer, translate'},
  'tri': {'meaning': '三', 'example': 'triangle, tricycle'},
  'ultra': {'meaning': '超', 'example': 'ultraviolet, ultimate'},
  'under': {'meaning': '不足，在下', 'example': 'understand, underestimate'},
  'up': {'meaning': '向上', 'example': 'update, upgrade, upright'},
  
  // Common suffixes
  'able': {'meaning': '能够...的', 'example': 'comfortable, readable'},
  'ible': {'meaning': '能够...的', 'example': 'possible, visible'},
  'al': {'meaning': '...的', 'example': 'national, personal'},
  'an': {'meaning': '...的人', 'example': 'American, musician'},
  'ance': {'meaning': '状态，性质', 'example': 'acceptance, appearance'},
  'ence': {'meaning': '状态，性质', 'example': 'difference, existence'},
  'ant': {'meaning': '...的人/物', 'example': 'assistant, applicant'},
  'ent': {'meaning': '...的', 'example': 'different, confident'},
  'ary': {'meaning': '与...有关的', 'example': 'ordinary, library'},
  'ory': {'meaning': '与...有关的', 'example': 'history, category'},
  'dom': {'meaning': '领域，状态', 'example': 'freedom, kingdom'},
  'ee': {'meaning': '受动者', 'example': 'employee, interviewee'},
  'er': {'meaning': '做...的人', 'example': 'teacher, worker'},
  'or': {'meaning': '做...的人', 'example': 'actor, director'},
  'ese': {'meaning': '...的', 'example': 'Chinese, Japanese'},
  'ful': {'meaning': '充满...的', 'example': 'beautiful, helpful'},
  'fy': {'meaning': '使...', 'example': 'simplify, classify'},
  'hood': {'meaning': '状态，身份', 'example': 'childhood, neighborhood'},
  'ing': {'meaning': '...的动作', 'example': 'reading, writing'},
  'ion': {'meaning': '动作，状态', 'example': 'action, education'},
  'tion': {'meaning': '动作，状态', 'example': 'information, situation'},
  'sion': {'meaning': '动作，状态', 'example': 'decision, discussion'},
  'ism': {'meaning': '主义，学说', 'example': 'capitalism, tourism'},
  'ist': {'meaning': '...的人', 'example': 'scientist, artist'},
  'ity': {'meaning': '性质，状态', 'example': 'ability, reality'},
  'ty': {'meaning': '性质，状态', 'example': 'safety, beauty'},
  'ive': {'meaning': '有...倾向的', 'example': 'creative, active'},
  'less': {'meaning': '没有...的', 'example': 'careless, homeless'},
  'ly': {'meaning': '...地', 'example': 'quickly, slowly'},
  'ment': {'meaning': '动作，结果', 'example': 'development, movement'},
  'ness': {'meaning': '状态，性质', 'example': 'happiness, darkness'},
  'ous': {'meaning': '有...性质的', 'example': 'dangerous, famous'},
  'ious': {'meaning': '有...性质的', 'example': 'curious, various'},
  'ship': {'meaning': '状态，身份', 'example': 'friendship, leadership'},
  'ure': {'meaning': '动作，结果', 'example': 'structure, culture'},
  'ward': {'meaning': '向...方向', 'example': 'forward, backward'},
  'wise': {'meaning': '以...方式', 'example': 'likewise, otherwise'},
  'y': {'meaning': '有...的', 'example': 'rainy, cloudy'},
};

const Map<String, List<Map<String, String>>> synonymGroups = {
  'happy': [
    {'word': 'glad', 'meaning': '高兴的'},
    {'word': 'pleased', 'meaning': '满意的'},
    {'word': 'delighted', 'meaning': '欣喜的'},
    {'word': 'joyful', 'meaning': '快乐的'},
    {'word': 'cheerful', 'meaning': '愉快的'},
  ],
  'sad': [
    {'word': 'unhappy', 'meaning': '不高兴的'},
    {'word': 'sorrowful', 'meaning': '悲伤的'},
    {'word': 'gloomy', 'meaning': '忧郁的'},
    {'word': 'depressed', 'meaning': '沮丧的'},
    {'word': 'melancholy', 'meaning': '忧伤的'},
  ],
  'big': [
    {'word': 'large', 'meaning': '大的'},
    {'word': 'huge', 'meaning': '巨大的'},
    {'word': 'enormous', 'meaning': '庞大的'},
    {'word': 'vast', 'meaning': '广阔的'},
    {'word': 'immense', 'meaning': '极大的'},
  ],
  'small': [
    {'word': 'tiny', 'meaning': '微小的'},
    {'word': 'little', 'meaning': '小的'},
    {'word': 'miniature', 'meaning': '微型的'},
    {'word': 'minute', 'meaning': '微小的'},
    {'word': 'compact', 'meaning': '紧凑的'},
  ],
  'good': [
    {'word': 'excellent', 'meaning': '优秀的'},
    {'word': 'fine', 'meaning': '好的'},
    {'word': 'wonderful', 'meaning': '精彩的'},
    {'word': 'great', 'meaning': '伟大的'},
    {'word': 'superb', 'meaning': '极好的'},
  ],
  'bad': [
    {'word': 'terrible', 'meaning': '可怕的'},
    {'word': 'awful', 'meaning': '糟糕的'},
    {'word': 'poor', 'meaning': '差的'},
    {'word': 'inferior', 'meaning': '劣等的'},
    {'word': 'dreadful', 'meaning': '可怕的'},
  ],
  'important': [
    {'word': 'significant', 'meaning': '重要的'},
    {'word': 'crucial', 'meaning': '关键的'},
    {'word': 'vital', 'meaning': '至关重要的'},
    {'word': 'essential', 'meaning': '必要的'},
    {'word': 'critical', 'meaning': '关键的'},
  ],
  'difficult': [
    {'word': 'hard', 'meaning': '困难的'},
    {'word': 'challenging', 'meaning': '有挑战性的'},
    {'word': 'tough', 'meaning': '艰难的'},
    {'word': 'complex', 'meaning': '复杂的'},
    {'word': 'complicated', 'meaning': '复杂的'},
  ],
  'beautiful': [
    {'word': 'pretty', 'meaning': '漂亮的'},
    {'word': 'attractive', 'meaning': '吸引人的'},
    {'word': 'gorgeous', 'meaning': '华丽的'},
    {'word': 'stunning', 'meaning': '极美的'},
    {'word': 'elegant', 'meaning': '优雅的'},
  ],
  'fast': [
    {'word': 'quick', 'meaning': '快的'},
    {'word': 'rapid', 'meaning': '迅速的'},
    {'word': 'swift', 'meaning': '敏捷的'},
    {'word': 'speedy', 'meaning': '快速的'},
    {'word': 'hasty', 'meaning': '匆忙的'},
  ],
  'slow': [
    {'word': 'sluggish', 'meaning': '缓慢的'},
    {'word': 'gradual', 'meaning': '逐渐的'},
    {'word': 'unhurried', 'meaning': '不慌不忙的'},
    {'word': 'leisurely', 'meaning': '悠闲的'},
    {'word': 'delayed', 'meaning': '延迟的'},
  ],
  'think': [
    {'word': 'consider', 'meaning': '考虑'},
    {'word': 'believe', 'meaning': '相信'},
    {'word': 'suppose', 'meaning': '假设'},
    {'word': 'assume', 'meaning': '假设'},
    {'word': 'reckon', 'meaning': '认为'},
  ],
  'see': [
    {'word': 'look', 'meaning': '看'},
    {'word': 'watch', 'meaning': '观看'},
    {'word': 'observe', 'meaning': '观察'},
    {'word': 'notice', 'meaning': '注意到'},
    {'word': 'spot', 'meaning': '发现'},
  ],
  'say': [
    {'word': 'speak', 'meaning': '说'},
    {'word': 'talk', 'meaning': '谈话'},
    {'word': 'tell', 'meaning': '告诉'},
    {'word': 'mention', 'meaning': '提及'},
    {'word': 'state', 'meaning': '陈述'},
  ],
  'get': [
    {'word': 'obtain', 'meaning': '获得'},
    {'word': 'acquire', 'meaning': '获取'},
    {'word': 'gain', 'meaning': '获得'},
    {'word': 'receive', 'meaning': '收到'},
    {'word': 'earn', 'meaning': '赚得'},
  ],
  'make': [
    {'word': 'create', 'meaning': '创造'},
    {'word': 'produce', 'meaning': '生产'},
    {'word': 'generate', 'meaning': '产生'},
    {'word': 'build', 'meaning': '建造'},
    {'word': 'construct', 'meaning': '构建'},
  ],
  'show': [
    {'word': 'display', 'meaning': '展示'},
    {'word': 'reveal', 'meaning': '揭示'},
    {'word': 'demonstrate', 'meaning': '演示'},
    {'word': 'indicate', 'meaning': '表明'},
    {'word': 'exhibit', 'meaning': '展览'},
  ],
  'help': [
    {'word': 'assist', 'meaning': '协助'},
    {'word': 'aid', 'meaning': '援助'},
    {'word': 'support', 'meaning': '支持'},
    {'word': 'facilitate', 'meaning': '促进'},
    {'word': 'contribute', 'meaning': '贡献'},
  ],
  'start': [
    {'word': 'begin', 'meaning': '开始'},
    {'word': 'commence', 'meaning': '开始'},
    {'word': 'initiate', 'meaning': '发起'},
    {'word': 'launch', 'meaning': '启动'},
    {'word': 'originate', 'meaning': '起源'},
  ],
  'end': [
    {'word': 'finish', 'meaning': '完成'},
    {'word': 'conclude', 'meaning': '结束'},
    {'word': 'terminate', 'meaning': '终止'},
    {'word': 'complete', 'meaning': '完成'},
    {'word': 'cease', 'meaning': '停止'},
  ],
};

const Map<String, List<Map<String, String>>> antonymGroups = {
  'happy': [
    {'word': 'sad', 'meaning': '悲伤的'},
    {'word': 'unhappy', 'meaning': '不高兴的'},
    {'word': 'miserable', 'meaning': '痛苦的'},
  ],
  'big': [
    {'word': 'small', 'meaning': '小的'},
    {'word': 'tiny', 'meaning': '微小的'},
    {'word': 'little', 'meaning': '小的'},
  ],
  'good': [
    {'word': 'bad', 'meaning': '坏的'},
    {'word': 'poor', 'meaning': '差的'},
    {'word': 'terrible', 'meaning': '糟糕的'},
  ],
  'hot': [
    {'word': 'cold', 'meaning': '冷的'},
    {'word': 'cool', 'meaning': '凉爽的'},
    {'word': 'freezing', 'meaning': '冰冻的'},
  ],
  'fast': [
    {'word': 'slow', 'meaning': '慢的'},
    {'word': 'sluggish', 'meaning': '缓慢的'},
  ],
  'easy': [
    {'word': 'difficult', 'meaning': '困难的'},
    {'word': 'hard', 'meaning': '艰难的'},
    {'word': 'challenging', 'meaning': '有挑战的'},
  ],
  'rich': [
    {'word': 'poor', 'meaning': '贫穷的'},
    {'word': 'broke', 'meaning': '破产的'},
  ],
  'strong': [
    {'word': 'weak', 'meaning': '虚弱的'},
    {'word': 'feeble', 'meaning': '无力的'},
  ],
  'young': [
    {'word': 'old', 'meaning': '年老的'},
    {'word': 'elderly', 'meaning': '上了年纪的'},
  ],
  'new': [
    {'word': 'old', 'meaning': '旧的'},
    {'word': 'ancient', 'meaning': '古老的'},
    {'word': 'used', 'meaning': '用过的'},
  ],
  'light': [
    {'word': 'heavy', 'meaning': '重的'},
    {'word': 'weighty', 'meaning': '沉重的'},
  ],
  'dark': [
    {'word': 'light', 'meaning': '明亮的'},
    {'word': 'bright', 'meaning': '明亮的'},
  ],
  'clean': [
    {'word': 'dirty', 'meaning': '脏的'},
    {'word': 'filthy', 'meaning': '污秽的'},
  ],
  'wet': [
    {'word': 'dry', 'meaning': '干燥的'},
  ],
  'full': [
    {'word': 'empty', 'meaning': '空的'},
    {'word': 'vacant', 'meaning': '空缺的'},
  ],
  'open': [
    {'word': 'close', 'meaning': '关闭'},
    {'word': 'shut', 'meaning': '关上'},
  ],
  'above': [
    {'word': 'below', 'meaning': '在下面'},
    {'word': 'beneath', 'meaning': '在下方'},
  ],
  'accept': [
    {'word': 'reject', 'meaning': '拒绝'},
    {'word': 'refuse', 'meaning': '拒绝'},
    {'word': 'decline', 'meaning': '谢绝'},
  ],
  'agree': [
    {'word': 'disagree', 'meaning': '不同意'},
    {'word': 'oppose', 'meaning': '反对'},
  ],
  'appear': [
    {'word': 'disappear', 'meaning': '消失'},
    {'word': 'vanish', 'meaning': '消失'},
  ],
  'arrive': [
    {'word': 'leave', 'meaning': '离开'},
    {'word': 'depart', 'meaning': '出发'},
  ],
  'attack': [
    {'word': 'defend', 'meaning': '防御'},
    {'word': 'protect', 'meaning': '保护'},
  ],
  'awake': [
    {'word': 'asleep', 'meaning': '睡着的'},
    {'word': 'sleeping', 'meaning': '正在睡觉的'},
  ],
  'brave': [
    {'word': 'cowardly', 'meaning': '胆小的'},
    {'word': 'timid', 'meaning': '胆怯的'},
  ],
  'careful': [
    {'word': 'careless', 'meaning': '粗心的'},
    {'word': 'reckless', 'meaning': '鲁莽的'},
  ],
  'certain': [
    {'word': 'uncertain', 'meaning': '不确定的'},
    {'word': 'doubtful', 'meaning': '可疑的'},
  ],
  'common': [
    {'word': 'rare', 'meaning': '罕见的'},
    {'word': 'unusual', 'meaning': '不寻常的'},
  ],
  'complex': [
    {'word': 'simple', 'meaning': '简单的'},
    {'word': 'easy', 'meaning': '容易的'},
  ],
  'create': [
    {'word': 'destroy', 'meaning': '破坏'},
    {'word': 'demolish', 'meaning': '摧毁'},
  ],
  'dangerous': [
    {'word': 'safe', 'meaning': '安全的'},
    {'word': 'secure', 'meaning': '安全的'},
  ],
  'deep': [
    {'word': 'shallow', 'meaning': '浅的'},
  ],
  'early': [
    {'word': 'late', 'meaning': '晚的'},
    {'word': 'delayed', 'meaning': '延迟的'},
  ],
  'far': [
    {'word': 'near', 'meaning': '近的'},
    {'word': 'close', 'meaning': '近的'},
  ],
  'give': [
    {'word': 'take', 'meaning': '拿'},
    {'word': 'receive', 'meaning': '接收'},
  ],
  'honest': [
    {'word': 'dishonest', 'meaning': '不诚实的'},
    {'word': 'lying', 'meaning': '说谎的'},
  ],
  'include': [
    {'word': 'exclude', 'meaning': '排除'},
    {'word': 'omit', 'meaning': '省略'},
  ],
  'increase': [
    {'word': 'decrease', 'meaning': '减少'},
    {'word': 'reduce', 'meaning': '降低'},
  ],
  'inside': [
    {'word': 'outside', 'meaning': '外面'},
  ],
  'join': [
    {'word': 'leave', 'meaning': '离开'},
    {'word': 'quit', 'meaning': '退出'},
  ],
  'know': [
    {'word': 'ignore', 'meaning': '忽视'},
    {'word': 'doubt', 'meaning': '怀疑'},
  ],
  'laugh': [
    {'word': 'cry', 'meaning': '哭'},
    {'word': 'weep', 'meaning': '哭泣'},
  ],
  'love': [
    {'word': 'hate', 'meaning': '恨'},
    {'word': 'dislike', 'meaning': '不喜欢'},
  ],
  'noisy': [
    {'word': 'quiet', 'meaning': '安静的'},
    {'word': 'silent', 'meaning': '沉默的'},
  ],
  'ordinary': [
    {'word': 'extraordinary', 'meaning': '非凡的'},
    {'word': 'special', 'meaning': '特别的'},
  ],
  'permanent': [
    {'word': 'temporary', 'meaning': '临时的'},
  ],
  'possible': [
    {'word': 'impossible', 'meaning': '不可能的'},
  ],
  'public': [
    {'word': 'private', 'meaning': '私人的'},
  ],
  'remember': [
    {'word': 'forget', 'meaning': '忘记'},
  ],
  'right': [
    {'word': 'wrong', 'meaning': '错误的'},
  ],
  'rise': [
    {'word': 'fall', 'meaning': '落下'},
    {'word': 'drop', 'meaning': '下降'},
  ],
  'same': [
    {'word': 'different', 'meaning': '不同的'},
  ],
  'serious': [
    {'word': 'funny', 'meaning': '有趣的'},
    {'word': 'humorous', 'meaning': '幽默的'},
  ],
  'short': [
    {'word': 'tall', 'meaning': '高的'},
    {'word': 'long', 'meaning': '长的'},
  ],
  'sick': [
    {'word': 'healthy', 'meaning': '健康的'},
    {'word': 'well', 'meaning': '好的'},
  ],
  'simple': [
    {'word': 'complex', 'meaning': '复杂的'},
    {'word': 'complicated', 'meaning': '复杂的'},
  ],
  'success': [
    {'word': 'failure', 'meaning': '失败'},
  ],
  'take': [
    {'word': 'give', 'meaning': '给'},
  ],
  'teach': [
    {'word': 'learn', 'meaning': '学习'},
  ],
  'thin': [
    {'word': 'thick', 'meaning': '厚的'},
    {'word': 'fat', 'meaning': '胖的'},
  ],
  'war': [
    {'word': 'peace', 'meaning': '和平'},
  ],
  'win': [
    {'word': 'lose', 'meaning': '输'},
  ],
  'with': [
    {'word': 'without', 'meaning': '没有'},
  ],
  'yes': [
    {'word': 'no', 'meaning': '不'},
  ],
};

List<String> analyzeWordRoots(String word) {
  final results = <String>[];
  
  // Check prefixes
  for (final entry in wordRoots.entries) {
    if (entry.key.length >= 2 && word.startsWith(entry.key) && word.length > entry.key.length + 2) {
      results.add('前缀 "${entry.key}": ${entry.value['meaning']} (如: ${entry.value['example']})');
    }
  }
  
  // Check suffixes
  for (final entry in wordRoots.entries) {
    if (entry.key.length >= 2 && word.endsWith(entry.key) && word.length > entry.key.length + 2) {
      results.add('后缀 "${entry.key}": ${entry.value['meaning']} (如: ${entry.value['example']})');
    }
  }
  
  return results;
}

List<Map<String, String>> getSynonyms(String word) {
  return synonymGroups[word.toLowerCase()] ?? [];
}

List<Map<String, String>> getAntonyms(String word) {
  return antonymGroups[word.toLowerCase()] ?? [];
}
